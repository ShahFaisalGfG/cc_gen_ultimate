import 'package:flutter/foundation.dart';
import 'package:cc_gen_ultimate/models/model_info.dart';
import 'package:cc_gen_ultimate/services/model_service.dart';

class ModelController extends ChangeNotifier {
  final ModelService _modelService = ModelService();
  ModelService get modelService => _modelService;
  ModelType _selectedType = ModelType.whisperAI;
  String _searchQuery = '';
  String _sortBy = 'name';
  String _groupBy = 'none';
  
  List<ModelInfo> _models = [];
  List<ModelInfo> get models => _filterAndSortModels();
  ModelType get selectedType => _selectedType;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  String get groupBy => _groupBy;

  ModelController() {
    _modelService.modelStatusStream.listen((models) {
      _models = models;
      notifyListeners();
    });
    _loadModels();
  }

  void _loadModels() {
    _models = _modelService.getAvailableModels(_selectedType);
    notifyListeners();
  }

  List<ModelInfo> _filterAndSortModels() {
    var filteredModels = _models.where((model) {
      if (_searchQuery.isEmpty) return true;
      return model.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_sortBy) {
      case 'name':
        filteredModels.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'size':
        filteredModels.sort((a, b) => a.sizeInMB.compareTo(b.sizeInMB));
        break;
      case 'date':
        filteredModels.sort((a, b) {
          if (a.lastUsed == null && b.lastUsed == null) return 0;
          if (a.lastUsed == null) return 1;
          if (b.lastUsed == null) return -1;
          return b.lastUsed!.compareTo(a.lastUsed!);
        });
        break;
    }

    return filteredModels;
  }

  void setSelectedType(ModelType type) {
    _selectedType = type;
    _loadModels();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void setGroupBy(String groupBy) {
    _groupBy = groupBy;
    notifyListeners();
  }

  Future<void> downloadModel(String modelName) async {
    await _modelService.downloadModel(modelName);
  }

  void cancelDownload(String modelName) {
    _modelService.cancelDownload(modelName);
  }

  Future<void> deleteModel(String modelName) async {
    await _modelService.deleteModel(modelName);
  }

  Future<void> verifyModel(String modelName) async {
    await _modelService.verifyModel(modelName);
  }

  @override
  void dispose() {
    _modelService.dispose();
    super.dispose();
  }
}
