import Foundation

extension Collection {

    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    /// https://stackoverflow.com/a/30593673/3386893
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

}
