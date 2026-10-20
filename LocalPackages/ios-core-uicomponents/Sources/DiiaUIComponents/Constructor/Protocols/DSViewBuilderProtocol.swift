
import UIKit
import DiiaCommonTypes

public protocol DSViewBuilderProtocol {
    static var key: String { get }
    var modelKey: String { get }
    func makeView(from object: AnyCodable,
                  withPadding padding: DSViewPaddingType,
                  viewFabric: DSViewFabric?,
                  eventHandler: @escaping (ConstructorItemEvent) -> Void) -> UIView?
}

public extension DSViewBuilderProtocol {
    var modelKey: String { Self.key }
}

public protocol DSViewMockableBuilderProtocol: DSViewBuilderProtocol {
    func makeMockModel() -> AnyCodable
    func makeMockView(withPadding padding: DSViewPaddingType,
                      viewFabric: DSViewFabric?,
                      eventHandler: @escaping (ConstructorItemEvent) -> Void) -> UIView?
}

public extension DSViewMockableBuilderProtocol {
    func makeMockView(withPadding padding: DSViewPaddingType,
                      viewFabric: DSViewFabric?,
                      eventHandler: @escaping (ConstructorItemEvent) -> Void
    ) -> UIView? {
        return makeView(from: makeMockModel(), withPadding: padding, viewFabric: viewFabric, eventHandler: eventHandler)
    }
}
