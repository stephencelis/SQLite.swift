import Foundation

#if swift(>=5.1)
/// A type that Expression a property marked with an attribute.
///```swift
///@Expressed("id") var id = UUID().string
///```
///
@propertyWrapper public struct Expressed<Value> where Value: SQLite.Value {
	///The property for which this instance exposes a Expression.
	public let projectedValue:Expression<Value>
	
	public var wrappedValue: Value
	///Creates a publisher with the provided initial value.
	public init(wrappedValue: Value, _ key: String, bindings: [Binding?] = []) {
		projectedValue =  Expression<Value>(key, bindings)
		self.wrappedValue = wrappedValue
	}
	public var setter:Setter { projectedValue <- wrappedValue }
}
#endif
