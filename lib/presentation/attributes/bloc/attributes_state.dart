part of 'attributes_cubit.dart';

abstract class AttributesState extends Equatable {
  const AttributesState();

  @override
  List<Object> get props => [];
}

class AttributesInitial extends AttributesState {}

class AttributesLoading extends AttributesState {}

class AttributesLoaded extends AttributesState {
  final List<Attribute> attributes;

  const AttributesLoaded(this.attributes);

  @override
  List<Object> get props => [attributes];
}

class AttributesError extends AttributesState {
  final String message;

  const AttributesError(this.message);

  @override
  List<Object> get props => [message];
}
