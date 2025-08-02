class ModelManagement {
  List<Map<String, dynamic>> downloadingModels = [];
  List<Map<String, dynamic>> downloadedModels = [
    {'name': 'tiny', 'size': '150MB', 'status': 'Completed'},
    {'name': 'base', 'size': '290MB', 'status': 'Completed'},
  ];
  List<Map<String, dynamic>> onlineModels = [
    {'name': 'small', 'size': '500MB'},
    {'name': 'medium', 'size': '1.5GB'},
    {'name': 'large', 'size': '2.9GB'},
  ];
  bool isDownloadingModel = false;

  void downloadModel(Map<String, dynamic> model) {
    // ...model download logic...
  }
  void cancelModelDownload(Map<String, dynamic> model) {
    // ...cancel logic...
  }
  void restartModelDownload(Map<String, dynamic> model) {
    // ...restart logic...
  }
  void deleteModel(Map<String, dynamic> model) {
    // ...delete logic...
  }
  void redownloadModel(Map<String, dynamic> model) {
    // ...redownload logic...
  }
}
