import 'package:cloud_firestore/cloud_firestore.dart';

class AsnCollectionManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String CURRENT_VERSION_DOC = 'asn_current_version';
  static const String METADATA_COLLECTION = 'collection_metadata';

  Future<int> getCurrentVersion() async {
    DocumentSnapshot versionDoc = await _firestore
        .collection(METADATA_COLLECTION)
        .doc(CURRENT_VERSION_DOC)
        .get();

    if (!versionDoc.exists) {
      // Initialize with version 1 if no version exists
      await _firestore
          .collection(METADATA_COLLECTION)
          .doc(CURRENT_VERSION_DOC)
          .set({'version': 1});
      return 1;
    }

    return (versionDoc.data() as Map<String, dynamic>)['version'] ?? 1;
  }

  Future<String> getCurrentCollectionName() async {
    int version = await getCurrentVersion();
    return version == 1 ? 'penilaian_asn' : 'penilaian_asn_$version';
  }

  Future<void> resetAndCreateNewCollection() async {
    // Get current version and calculate next version
    int currentVersion = await getCurrentVersion();
    int newVersion = currentVersion + 1;
    
    // Get all documents from current collection
    String currentCollectionName = await getCurrentCollectionName();
    QuerySnapshot currentDocs = await _firestore
        .collection(currentCollectionName)
        .get();

    // Copy all documents to archive collection
    String archiveCollectionName = 'archived_$currentCollectionName';
    WriteBatch batch = _firestore.batch();
    
    for (var doc in currentDocs.docs) {
      DocumentReference archiveRef = _firestore
          .collection(archiveCollectionName)
          .doc(doc.id);
      batch.set(archiveRef, {
        ...doc.data() as Map<String, dynamic>,
        'archived_at': FieldValue.serverTimestamp(),
      });
    }

    // Update version in metadata
    batch.set(
      _firestore.collection(METADATA_COLLECTION).doc(CURRENT_VERSION_DOC),
      {'version': newVersion}
    );

    // Execute batch
    await batch.commit();
  }

  Future<List<String>> getAvailableCollections() async {
    int currentVersion = await getCurrentVersion();
    List<String> collections = [];
    
    for (int i = 1; i <= currentVersion; i++) {
      String collectionName = i == 1 ? 'penilaian_asn' : 'penilaian_asn_$i';
      collections.add(collectionName);
    }
    
    return collections;
  }
}


class NonAsnCollectionManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String CURRENT_VERSION_DOC = 'non_as_current_version';
  static const String METADATA_COLLECTION = 'collection_metadata';

  Future<int> getCurrentVersion() async {
    DocumentSnapshot versionDoc = await _firestore
        .collection(METADATA_COLLECTION)
        .doc(CURRENT_VERSION_DOC)
        .get();

    if (!versionDoc.exists) {
      // Initialize with version 1 if no version exists
      await _firestore
          .collection(METADATA_COLLECTION)
          .doc(CURRENT_VERSION_DOC)
          .set({'version': 1});
      return 1;
    }

    return (versionDoc.data() as Map<String, dynamic>)['version'] ?? 1;
  }

  Future<String> getCurrentCollectionName() async {
    int version = await getCurrentVersion();
    return version == 1 ? 'penilaian_non_asn' : 'penilaian_non_asn_$version';
  }

  Future<void> resetAndCreateNewCollection() async {
    // Get current version and calculate next version
    int currentVersion = await getCurrentVersion();
    int newVersion = currentVersion + 1;
    
    // Get all documents from current collection
    String currentCollectionName = await getCurrentCollectionName();
    QuerySnapshot currentDocs = await _firestore
        .collection(currentCollectionName)
        .get();

    // Copy all documents to archive collection
    String archiveCollectionName = 'archived_$currentCollectionName';
    WriteBatch batch = _firestore.batch();
    
    for (var doc in currentDocs.docs) {
      DocumentReference archiveRef = _firestore
          .collection(archiveCollectionName)
          .doc(doc.id);
      batch.set(archiveRef, {
        ...doc.data() as Map<String, dynamic>,
        'archived_at': FieldValue.serverTimestamp(),
      });
    }

    // Update version in metadata
    batch.set(
      _firestore.collection(METADATA_COLLECTION).doc(CURRENT_VERSION_DOC),
      {'version': newVersion}
    );

    // Execute batch
    await batch.commit();
  }

  Future<List<String>> getAvailableCollections() async {
    int currentVersion = await getCurrentVersion();
    List<String> collections = [];
    
    for (int i = 1; i <= currentVersion; i++) {
      String collectionName = i == 1 ? 'penilaian_non_asn' : 'penilaian_non_asn_$i';
      collections.add(collectionName);
    }
    
    return collections;
  }
}