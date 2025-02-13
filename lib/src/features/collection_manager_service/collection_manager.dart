import 'package:cloud_firestore/cloud_firestore.dart';

class AsnCollectionManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String CURRENT_VERSION_DOC = 'asn_current_version';
  static const String METADATA_COLLECTION = 'collection_metadata';
  static const String FIRST_COLLECTION_NAME = 'penilaian_asn';

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

  // Improved update version method
  Future<void> updateCurrentVersion(int newVersion) async {
    try {
      await _firestore
          .collection(METADATA_COLLECTION)
          .doc(CURRENT_VERSION_DOC)
          .set({
            'version': newVersion,
            'updated_at': FieldValue.serverTimestamp(),
          });
      print('Successfully updated version to: $newVersion'); // Debug log
    } catch (e) {
      print('Error updating version: $e'); // Debug log
      throw e; // Re-throw to handle in calling function
    }
  }

  // New method to find the highest available version
  Future<int> findHighestAvailableVersion() async {
    // Get deleted collection
    DocumentSnapshot deletedCollectionsDoc = await _firestore
        .collection(METADATA_COLLECTION)
        .doc('deleted_collections')
        .get();

    Map<String, dynamic> deletedCollections =
        deletedCollectionsDoc.exists ? (deletedCollectionsDoc.data() as Map<String, dynamic>) : {};

    // Get current version
    int currentVersion = await getCurrentVersion();

    // Find the highest available version
    for (int i = currentVersion; i >= 1; i--){
      String collectionName = i == 1 ? 'penilaian_asn' : 'penilaian_asn_$i';

      // Check if collection exists and is not deleted
      if (!deletedCollections.containsKey(collectionName)) {
        // Verify collection actually has documents
        QuerySnapshot collectionDocs = await _firestore
            .collection(collectionName)
            .limit(1)
            .get();
            
        if (collectionDocs.docs.isNotEmpty) {
          return i;
        }
      }
    }

    return 1;
  }

  Future<String> getCurrentCollectionName() async {
    int version = await getCurrentVersion();
    return version == 1 ? 'penilaian_asn' : 'penilaian_asn_$version';
  }

  Future<void> resetAndCreateNewCollection() async {
    try {
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

      // Get deleted collections document
      DocumentSnapshot deletedCollectionsDoc = await _firestore
          .collection(METADATA_COLLECTION)
          .doc('deleted_collections')
          .get();

      Map<String, dynamic> deletedCollections = 
          deletedCollectionsDoc.exists ? (deletedCollectionsDoc.data() as Map<String, dynamic>) : {};

      // Remove entries for any previously deleted collections with this new version number
      String newCollectionName = newVersion == 1 ? 'penilaian_asn' : 'penilaian_asn_$newVersion';
      if (deletedCollections.containsKey(newCollectionName)) {
        deletedCollections.remove(newCollectionName);
        
        // Update deleted_collections document
        batch.set(
          _firestore.collection(METADATA_COLLECTION).doc('deleted_collections'),
          deletedCollections
        );
      }

      // Update version in metadata
      batch.set(
        _firestore.collection(METADATA_COLLECTION).doc(CURRENT_VERSION_DOC),
        {
          'version': newVersion,
          'updated_at': FieldValue.serverTimestamp(),
        }
      );

      // Execute batch
      await batch.commit();
      
      print('Successfully reset and created new collection: $newCollectionName'); // Debug log
    } catch (e) {
      print('Error in resetAndCreateNewCollection: $e'); // Debug log
      throw e;
    }
  }

  // New helper method to clean deleted collections
  Future<void> cleanDeletedCollections() async {
    try {
      DocumentSnapshot deletedCollectionsDoc = await _firestore
          .collection(METADATA_COLLECTION)
          .doc('deleted_collections')
          .get();

      if (deletedCollectionsDoc.exists) {
        Map<String, dynamic> deletedCollections = 
            deletedCollectionsDoc.data() as Map<String, dynamic>;

        // Get current version
        int currentVersion = await getCurrentVersion();
        
        // Create new map without entries for current or future versions
        Map<String, dynamic> cleanedCollections = {};
        deletedCollections.forEach((key, value) {
          if (key == 'penilaian_asn') {
            if (currentVersion > 1) {
              cleanedCollections[key] = value;
            }
          } else {
            // Extract version number from collection name
            int version = int.tryParse(key.split('_').last) ?? 0;
            if (version < currentVersion) {
              cleanedCollections[key] = value;
            }
          }
        });

        // Update deleted_collections document
        await _firestore
            .collection(METADATA_COLLECTION)
            .doc('deleted_collections')
            .set(cleanedCollections);
            
        print('Successfully cleaned deleted collections'); // Debug log
      }
    } catch (e) {
      print('Error cleaning deleted collections: $e'); // Debug log
      throw e;
    }
  }

  Future<List<String>> getAvailableCollections() async {
    int currentVersion = await getCurrentVersion();
    List<String> collections = [];

    //Get delete collections
    DocumentSnapshot deletedCollectionsDoc = await _firestore
        .collection(METADATA_COLLECTION)
        .doc('deleted_collections')
        .get();

    Map<String, dynamic> deletedCollections =
        deletedCollectionsDoc.exists ? (deletedCollectionsDoc.data() as Map<String, dynamic>) : {};
    
    // Special check for first collection (penilaian_asn)
    if (deletedCollections.containsKey(FIRST_COLLECTION_NAME)) {
      // Check if there's actually data in the collection
      QuerySnapshot firstCollectionDocs = await _firestore
          .collection(FIRST_COLLECTION_NAME)
          .limit(1)
          .get();
          
      if (firstCollectionDocs.docs.isNotEmpty) {
        // If there's data, remove it from deleted_collections
        deletedCollections.remove(FIRST_COLLECTION_NAME);
        await _firestore
            .collection(METADATA_COLLECTION)
            .doc('deleted_collections')
            .set(deletedCollections);
      }
    }

    for (int i = 1; i <= currentVersion; i++) {
      String collectionName = i == 1 ? FIRST_COLLECTION_NAME : 'penilaian_asn_$i';
      if (!deletedCollections.containsKey(collectionName)){
        // Verify the collection has documents
        QuerySnapshot collectionDocs = await _firestore
            .collection(collectionName)
            .limit(1)
            .get();
            
        if (collectionDocs.docs.isNotEmpty) {
          collections.add(collectionName);
        }
      }
    }
    
    return collections;
  }

  // Add a new method to handle first collection data changes
  Future<void> setupCollectionChangeListener() async {
    _firestore
        .collection(FIRST_COLLECTION_NAME)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        // If data exists, ensure it's not in deleted_collections
        DocumentSnapshot deletedCollectionsDoc = await _firestore
            .collection(METADATA_COLLECTION)
            .doc('deleted_collections')
            .get();
        
        if (deletedCollectionsDoc.exists) {
          Map<String, dynamic> deletedCollections = 
              deletedCollectionsDoc.data() as Map<String, dynamic>;
              
          if (deletedCollections.containsKey(FIRST_COLLECTION_NAME)) {
            // Remove from deleted_collections
            deletedCollections.remove(FIRST_COLLECTION_NAME);
            await _firestore
                .collection(METADATA_COLLECTION)
                .doc('deleted_collections')
                .set(deletedCollections);
                
            print('Removed $FIRST_COLLECTION_NAME from deleted_collections due to new data');
          }
        }
      }
    });
  }
}


class NonAsnCollectionManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String CURRENT_VERSION_DOC = 'non_asn_current_version';
  static const String METADATA_COLLECTION = 'collection_metadata';
  static const String FIRST_COLLECTION_NAME = 'penilaian_non_asn';

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

  // Improved update version method
  Future<void> updateCurrentVersion(int newVersion) async {
    try {
      await _firestore
          .collection(METADATA_COLLECTION)
          .doc(CURRENT_VERSION_DOC)
          .set({
            'version': newVersion,
            'updated_at': FieldValue.serverTimestamp(),
          });
      print('Successfully updated version to: $newVersion'); // Debug log
    } catch (e) {
      print('Error updating version: $e'); // Debug log
      throw e; // Re-throw to handle in calling function
    }
  }

  // New method to find the highest available version
  Future<int> findHighestAvailableVersion() async {
    // Get deleted collections
    DocumentSnapshot deletedCollectionsDoc = await _firestore
        .collection(METADATA_COLLECTION)
        .doc('deleted_collections')
        .get();
    
    Map<String, dynamic> deletedCollections = 
        deletedCollectionsDoc.exists ? (deletedCollectionsDoc.data() as Map<String, dynamic>) : {};

    // Get current version
    int currentVersion = await getCurrentVersion();
    
    // Start from current version and work backwards
    for (int i = currentVersion; i >= 1; i--) {
      String collectionName = i == 1 ? 'penilaian_non_asn' : 'penilaian_non_asn_$i';
      
      // Check if collection exists and is not deleted
      if (!deletedCollections.containsKey(collectionName)) {
        // Verify collection actually has documents
        QuerySnapshot collectionDocs = await _firestore
            .collection(collectionName)
            .limit(1)
            .get();
            
        if (collectionDocs.docs.isNotEmpty) {
          return i;
        }
      }
    }
    
    return 1; // Default to 1 if no valid collections found
  }

  Future<String> getCurrentCollectionName() async {
    int version = await getCurrentVersion();
    return version == 1 ? 'penilaian_non_asn' : 'penilaian_non_asn_$version';
  }

  Future<void> resetAndCreateNewCollection() async {
    try {
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

      // Get deleted collections document
      DocumentSnapshot deletedCollectionsDoc = await _firestore
          .collection(METADATA_COLLECTION)
          .doc('deleted_collections')
          .get();

      Map<String, dynamic> deletedCollections = 
          deletedCollectionsDoc.exists ? (deletedCollectionsDoc.data() as Map<String, dynamic>) : {};

      // Remove entries for any previously deleted collections with this new version number
      String newCollectionName = newVersion == 1 ? 'penilaian_non_asn' : 'penilaian_non_asn_$newVersion';
      if (deletedCollections.containsKey(newCollectionName)) {
        deletedCollections.remove(newCollectionName);
        
        // Update deleted_collections document
        batch.set(
          _firestore.collection(METADATA_COLLECTION).doc('deleted_collections'),
          deletedCollections
        );
      }

      // Update version in metadata
      batch.set(
        _firestore.collection(METADATA_COLLECTION).doc(CURRENT_VERSION_DOC),
        {
          'version': newVersion,
          'updated_at': FieldValue.serverTimestamp(),
        }
      );

      // Execute batch
      await batch.commit();
      
      print('Successfully reset and created new collection: $newCollectionName'); // Debug log
    } catch (e) {
      print('Error in resetAndCreateNewCollection: $e'); // Debug log
      throw e;
    }
  }

  // New helper method to clean deleted collections
  Future<void> cleanDeletedCollections() async {
    try {
      DocumentSnapshot deletedCollectionsDoc = await _firestore
          .collection(METADATA_COLLECTION)
          .doc('deleted_collections')
          .get();

      if (deletedCollectionsDoc.exists) {
        Map<String, dynamic> deletedCollections = 
            deletedCollectionsDoc.data() as Map<String, dynamic>;

        // Get current version
        int currentVersion = await getCurrentVersion();
        
        // Create new map without entries for current or future versions
        Map<String, dynamic> cleanedCollections = {};
        deletedCollections.forEach((key, value) {
          if (key == 'penilaian_non_asn') {
            if (currentVersion > 1) {
              cleanedCollections[key] = value;
            }
          } else {
            // Extract version number from collection name
            int version = int.tryParse(key.split('_').last) ?? 0;
            if (version < currentVersion) {
              cleanedCollections[key] = value;
            }
          }
        });

        // Update deleted_collections document
        await _firestore
            .collection(METADATA_COLLECTION)
            .doc('deleted_collections')
            .set(cleanedCollections);
            
        print('Successfully cleaned deleted collections'); // Debug log
      }
    } catch (e) {
      print('Error cleaning deleted collections: $e'); // Debug log
      throw e;
    }
  }


  Future<List<String>> getAvailableCollections() async {
    int currentVersion = await getCurrentVersion();
    List<String> collections = [];

    // Get deleted collections
    DocumentSnapshot deletedCollectionsDoc = await _firestore
        .collection(METADATA_COLLECTION)
        .doc('deleted_collections')
        .get();
    
    Map<String, dynamic> deletedCollections = 
        deletedCollectionsDoc.exists ? (deletedCollectionsDoc.data() as Map<String, dynamic>) : {};

    // Special check for first collection (penilaian_asn)
    if (deletedCollections.containsKey(FIRST_COLLECTION_NAME)) {
      // Check if there's actually data in the collection
      QuerySnapshot firstCollectionDocs = await _firestore
          .collection(FIRST_COLLECTION_NAME)
          .limit(1)
          .get();
          
      if (firstCollectionDocs.docs.isNotEmpty) {
        // If there's data, remove it from deleted_collections
        deletedCollections.remove(FIRST_COLLECTION_NAME);
        await _firestore
            .collection(METADATA_COLLECTION)
            .doc('deleted_collections')
            .set(deletedCollections);
      }
    }
    
    for (int i = 1; i <= currentVersion; i++) {
      String collectionName = i == 1 ? FIRST_COLLECTION_NAME : 'penilaian_non_asn_$i';
      if (!deletedCollections.containsKey(collectionName)){
        // Verify the collection has documents
        QuerySnapshot collectionDocs = await _firestore
            .collection(collectionName)
            .limit(1)
            .get();
            
        if (collectionDocs.docs.isNotEmpty) {
          collections.add(collectionName);
        }
      }
    }
    
    return collections;
  }

  // Add a new method to handle first collection data changes
  Future<void> setupCollectionChangeListener() async {
    _firestore
        .collection(FIRST_COLLECTION_NAME)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        // If data exists, ensure it's not in deleted_collections
        DocumentSnapshot deletedCollectionsDoc = await _firestore
            .collection(METADATA_COLLECTION)
            .doc('deleted_collections')
            .get();
        
        if (deletedCollectionsDoc.exists) {
          Map<String, dynamic> deletedCollections = 
              deletedCollectionsDoc.data() as Map<String, dynamic>;
              
          if (deletedCollections.containsKey(FIRST_COLLECTION_NAME)) {
            // Remove from deleted_collections
            deletedCollections.remove(FIRST_COLLECTION_NAME);
            await _firestore
                .collection(METADATA_COLLECTION)
                .doc('deleted_collections')
                .set(deletedCollections);
                
            print('Removed $FIRST_COLLECTION_NAME from deleted_collections due to new data');
          }
        }
      }
    });
  }
  
}