//
//  TransactionDetailsDocumentClaimsMapper.swift
//

import Foundation
import WalletCore
import WalletDomainModels

protocol TransactionDetailsDocumentClaimsMapperProtocol {
    func map(_ documents: [Credential]) -> [ParsedDocumentClaims]
}

struct TransactionDetailsDocumentClaimsMapper: TransactionDetailsDocumentClaimsMapperProtocol {
    private let hiddenImageClaimNames = ["portrait", "picture", "photo", "image", "signature"]
    private let hiddenTechnicalClaimNames = ["cnf", "status", "lss"]
    private let drivingPrivilegesClaimName = "driving_privileges"
    private let vehicleCategoryCodeClaimName = "vehicle_category_code"

    func map(_ documents: [Credential]) -> [ParsedDocumentClaims] {
        documents.map(mapDocument)
    }

    private func mapDocument(_ doc: Credential) -> ParsedDocumentClaims {
        let parsed = parseDocClaims(doc.claims)
        let flatItems = parsed.dictionary
            .sorted { $0.key.uppercased() < $1.key.uppercased() }
            .map { (label: $0.key, value: $0.value) }
        let nestedItems = parsed.nestedItems.map {
            ParsedNestedClaims(title: $0.title, items: $0.items)
        }

        return ParsedDocumentClaims(
            displayName: doc.displayName ?? "",
            flatItems: flatItems,
            nestedItems: nestedItems
        )
    }

    private func parseDocClaims(
        _ claims: [DocumentClaim],
        parentTitle: String? = nil
    ) -> (dictionary: [String: String], nestedItems: [ParsedNestedItem]) {
        var nestedItemsArray: [ParsedNestedItem] = []
        var items: [String: String] = [:]

        claims.forEach { claim in
            guard !shouldSkipClaim(claim) else { return }

            let claimTitle = claim.displayName ?? claim.name
            let title = claimTitle.isEmpty ? parentTitle ?? "" : claimTitle

            if claim.name == drivingPrivilegesClaimName, let privileges = claim.children {
                // An array of privilege records. Group them into a single
                // "Driving Privileges" block with one row per record showing its
                // vehicle category code.
                let categoryLabel = WalletStringKey.eudiLabelVehicleCategoryCode.localized()
                let categoryRows: [(String, String)] = privileges.compactMap { privilege in
                    guard let category = privilege.children?
                            .first(where: { $0.name == vehicleCategoryCodeClaimName }),
                          !category.stringValue.isEmpty
                    else { return nil }
                    return (categoryLabel, category.stringValue)
                }
                if !categoryRows.isEmpty {
                    nestedItemsArray.append(ParsedNestedItem(title: title, items: categoryRows))
                }
            } else if let nested = claim.children {
                let result = parseDocClaims(nested, parentTitle: title)
                let nestedItems = result.dictionary.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
                if !nestedItems.isEmpty {
                    nestedItemsArray.append(
                        ParsedNestedItem(
                            title: title,
                            items: nestedItems
                        )
                    )
                }
            } else if shouldSkipImageClaim(claim) {
            } else if let date = claim.dataValue.dateValue {
                items[title] = "\(date.toLongDateString())"
            } else {
                items[title] = claim.stringValue
            }
        }

        return (items, nestedItemsArray)
    }

    private func shouldSkipImageClaim(_ claim: DocumentClaim) -> Bool {
        if claim.dataValue.imageData != nil {
            return true
        }
        return hiddenImageClaimNames.contains(claim.name.lowercased())
    }

    private func shouldSkipClaim(_ claim: DocumentClaim) -> Bool {
        return hiddenTechnicalClaimNames.contains(claim.name.lowercased())
    }
}

struct ParsedDocumentClaims {
    let displayName: String
    let flatItems: [(label: String, value: String)]
    let nestedItems: [ParsedNestedClaims]
}

struct ParsedNestedClaims {
    let title: String
    let items: [(label: String, value: String)]
}

private struct ParsedNestedItem {
    let title: String
    let items: [(String, String)]
}
