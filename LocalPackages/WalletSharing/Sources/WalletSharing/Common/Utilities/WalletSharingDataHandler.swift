//
//  WalletSharingDataHandler.swift
//

import Foundation
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

final class WalletSharingDataHandler {
    
    private var docValues: DocValues = [:]
    
    // MARK: - Public Methods
    public func prepareConstructorModel(for request: PresentationRequest) -> DSConstructorModel {
        docValues = request.items.reduce(into: DocValues()) { requestedDocs, item in
            guard let document = WalletDependencies.walletController.fetchDocument(with: item.id) else { return }

            let resolvedValueName: (String) -> String? = { elementIdentifier in
                let directClaimsMap = Dictionary(keepingFirst: document.claims.map {
                    ($0.name, $0.stringValue)
                })

                if let directValue = directClaimsMap[elementIdentifier], !directValue.isEmpty {
                    return directValue
                }

                switch elementIdentifier {
                case ClaimKeys.placeOfBirth:
                    if let directValue = document.claims.first(where: { $0.name == ClaimKeys.birthPlace })?.stringValue,
                       !directValue.isEmpty {
                        return directValue
                    }

                    guard let placeOfBirthClaim = document.claims.first(where: { $0.name == ClaimKeys.placeOfBirth }),
                          let children = placeOfBirthClaim.children,
                          !children.isEmpty
                    else { return nil }

                    let childrenMap = Dictionary(keepingFirst: children.map {
                        ($0.name, $0.stringValue)
                    })

                    return [
                        childrenMap[ClaimKeys.locality],
                        childrenMap[ClaimKeys.region],
                        childrenMap[ClaimKeys.country]
                    ]
                    .compactMap { $0 }
                    .first(where: { !$0.isEmpty })

                case ClaimKeys.nationality, ClaimKeys.nationalities:
                    for key in [ClaimKeys.nationalities, ClaimKeys.nationality] {
                        if let directValue = document.claims.first(where: { $0.name == key })?.stringValue,
                           !directValue.isEmpty {
                            return directValue
                        }

                        if let claim = document.claims.first(where: { $0.name == key }),
                           let children = claim.children,
                           !children.isEmpty {
                            let values = children.map(\.stringValue).filter { !$0.isEmpty }
                            let joined = values.joined(separator: ", ")
                            if !joined.isEmpty {
                                return joined
                            }
                        }
                    }

                    return nil

                case ClaimKeys.drivingPrivileges:
                    // Structured claim: an array of privilege records, each with its own
                    // sub-fields. Its own stringValue is empty, so join the per-privilege
                    // vehicle category codes (e.g. "B1, D1") for display.
                    guard let privilegesClaim = document.claims.first(where: { $0.name == ClaimKeys.drivingPrivileges }),
                          let privileges = privilegesClaim.children,
                          !privileges.isEmpty
                    else { return nil }

                    let categories = privileges
                        .compactMap { privilege in
                            privilege.children?
                                .first(where: { $0.name == ClaimKeys.vehicleCategoryCode })?
                                .stringValue
                        }
                        .filter { !$0.isEmpty }

                    let joined = categories.joined(separator: ", ")
                    return joined.isEmpty ? nil : joined

                default:
                    // The early non-empty check above already returned any usable direct value.
                    // Reaching here means the direct value was nil or empty — treat as absent so
                    // we don't emit a sharing row with a blank `valueName`.
                    return nil
                }
            }

            // Iterate every requested namespace, not just the first — a multi-namespace request (e.g. an mDL spanning the ISO and a national namespace) would otherwise lose all but one.
            // Key by namespace + element so identically-named elements in different namespaces don't collide.
            var requestedFields: [String: DocItemValue] = [:]
            for (namespace, requestItems) in item.selectedItemsDictionary {
                for requestItem in requestItems {
                    let elementIdentifier = requestItem.elementIdentifier

                    guard let docDisplayName = document.displayName,
                          let valueName = resolvedValueName(elementIdentifier)
                    else { continue }
                    // Falls back to the credential's own claim displayName, then to the element path, then to the raw identifier.
                    // See `WalletStringKey.claimLabel(forElementIdentifier:)` for the naming convention and the future doc-type-scoping extension point.
                    let localizedTitle = WalletStringKey.claimLabel(forElementIdentifier: elementIdentifier)?.localized()
                    let claimDisplayName = document.claims.first(where: { $0.name == elementIdentifier })?.displayName
                    let alternativeDisplayName = claimDisplayName ?? requestItem.elementPath.first ?? elementIdentifier
                    requestedFields[Self.docValueKey(namespace: namespace, elementIdentifier: elementIdentifier)] = DocItemValue(
                        namespace: namespace,
                        elementIdentifier: elementIdentifier,
                        docType: item.docTypeOrVct,
                        documentDisplayName: docDisplayName,
                        isOptional: requestItem.isOptional ?? true,
                        displayName: DocItemDisplayName(
                            title: localizedTitle ?? alternativeDisplayName,
                            subtitle: nil
                        ),
                        valueName: valueName
                    )
                }
            }

            guard !requestedFields.isEmpty else { return }
            requestedDocs[document.id] = requestedFields
        }
        
        let requestAdapter = WalletDisclosureRequestAdapter(
            relyingParty: request.relyingParty,
            docValues: docValues
        )
        return requestAdapter.getContructorModel()
    }
    
    public func transformAnyCodableToRequest(input: [String: AnyCodable]) -> SharingDisclosure {
        return input.reduce(into: [:]) { partialResult, inputItem in
            guard case let .bool(isSelected) = inputItem.value, isSelected else { return }
            guard let parsed = Self.parseInputCode(inputItem.key),
                  let element = docValues[parsed.docId]?[parsed.key]
            else { return }
            let field = RequestedField(elementIdentifier: element.elementIdentifier)
            partialResult[parsed.docId, default: [:]][element.namespace, default: []].append(field)
        }
    }

    public func getDocItem(forInputCode inputCode: String) -> DocItemValue? {
        guard let parsed = Self.parseInputCode(inputCode) else { return nil }
        return docValues[parsed.docId]?[parsed.key]
    }
}

private extension WalletSharingDataHandler {
    enum Constants {
        static let keySeparator = "/"
    }

    /// Composite `DocValues` key: namespacing the element identifier stops identically-named elements in different namespaces from colliding within one document.
    static func docValueKey(namespace: String, elementIdentifier: String) -> String {
        return namespace + Constants.keySeparator + elementIdentifier
    }

    /// Parse a checkbox `inputCode` ("<namespace>/<element>/<docId>") back into the document id and `DocValues` key.
    /// The document id is the last path component and the key is everything before it, so a namespace or element containing the separator survives as long as the document id has none.
    static func parseInputCode(_ inputCode: String) -> (docId: String, key: String)? {
        let components = inputCode.components(separatedBy: Constants.keySeparator)
        guard components.count >= 2, let docId = components.last else { return nil }
        let key = components.dropLast().joined(separator: Constants.keySeparator)
        guard !key.isEmpty else { return nil }
        return (docId, key)
    }

    enum ClaimKeys {
        static let placeOfBirth = "place_of_birth"
        static let birthPlace = "birth_place"
        static let locality = "locality"
        static let region = "region"
        static let country = "country"
        static let nationality = "nationality"
        static let nationalities = "nationalities"
        static let drivingPrivileges = "driving_privileges"
        static let vehicleCategoryCode = "vehicle_category_code"
    }
}
