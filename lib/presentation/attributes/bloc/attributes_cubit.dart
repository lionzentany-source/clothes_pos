import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clothes_pos/data/models/attribute.dart';
import 'package:clothes_pos/data/repositories/attribute_repository.dart';

part 'attributes_state.dart';

class AttributesCubit extends Cubit<AttributesState> {
  final AttributeRepository _attributeRepository;

  /// Public getter used by UI widgets that need direct access for
  /// convenience (e.g. to fetch attribute values in FutureBuilders).
  AttributeRepository get attributeRepository => _attributeRepository;

  AttributesCubit(this._attributeRepository) : super(AttributesInitial());

  Future<void> loadAttributes() async {
    try {
      emit(AttributesLoading());
      final attributes = await _attributeRepository.getAllAttributes();
      emit(AttributesLoaded(attributes));
    } catch (e) {
      emit(AttributesError(e.toString()));
    }
  }

  Future<void> addAttribute(Attribute attribute) async {
    try {
      await _attributeRepository.createAttribute(attribute);
      loadAttributes(); // Reload attributes after adding
    } catch (e) {
      emit(AttributesError(e.toString()));
    }
  }

  Future<void> updateAttribute(Attribute attribute) async {
    try {
      await _attributeRepository.updateAttribute(attribute);
      loadAttributes(); // Reload attributes after updating
    } catch (e) {
      emit(AttributesError(e.toString()));
    }
  }

  Future<void> deleteAttribute(int id) async {
    try {
      await _attributeRepository.deleteAttribute(id);
      loadAttributes(); // Reload attributes after deleting
    } catch (e) {
      emit(AttributesError(e.toString()));
    }
  }

  Future<void> addAttributeValue(AttributeValue value) async {
    try {
      await _attributeRepository.createAttributeValue(value);
      loadAttributes(); // Reload attributes after adding value
    } catch (e) {
      emit(AttributesError(e.toString()));
    }
  }

  Future<void> updateAttributeValue(AttributeValue value) async {
    try {
      await _attributeRepository.updateAttributeValue(value);
      loadAttributes(); // Reload attributes after updating value
    } catch (e) {
      emit(AttributesError(e.toString()));
    }
  }

  Future<void> deleteAttributeValue(int id) async {
    try {
      await _attributeRepository.deleteAttributeValue(id);
      loadAttributes(); // Reload attributes after deleting value
    } catch (e) {
      emit(AttributesError(e.toString()));
    }
  }
}
