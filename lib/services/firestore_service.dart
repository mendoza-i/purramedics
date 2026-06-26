import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

/// ============================================================================
/// FIRESTORE SERVICE
/// ----------------------------------------------------------------------------
/// Handles real-time database operations (The "Faucet" & "Pipe").
/// FEATURES:
/// 1. Add Event: Saves an event to the cloud.
/// 2. Get Events: Streams events in real-time to all users.
/// ============================================================================
class FirestoreService {
  final CollectionReference _eventsCollection = FirebaseFirestore.instance
      .collection('events');

  // Add Event (For Vets)
  Future<void> addEvent(Event event) async {
    await _eventsCollection.add({
      'title': event.title,
      'location': event.location,
      'date': event.date,
      'colorValue': event.colorValue,
      'description': event.description,
      'iconName': event.iconName,
      'createdAt': FieldValue.serverTimestamp(), // For sorting
    });
  }

  // Get Events Stream (For Home Page - Returning Objects)
  Stream<List<Event>> getEventsStream() {
    return _eventsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Event(
              title: data['title'] ?? '',
              location: data['location'] ?? '',
              date: data['date'] ?? '',
              colorValue: data['colorValue'] ?? 0xFF000000,
              description: data['description'] ?? '',
              iconName: data['iconName'] ?? 'default',
            );
          }).toList();
        });
  }

  // Get Events Dictionary Stream (For Vet - Includes ID for Edit/Delete)
  Stream<List<Map<String, dynamic>>> getEventsStreamMap() {
    return _eventsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Update Event
  Future<void> updateEvent(
    String id,
    String title,
    String loc,
    String date,
    int color,
    String desc,
    String icon,
  ) async {
    await _eventsCollection.doc(id).update({
      'title': title,
      'location': loc,
      'date': date,
      'colorValue': color,
      'description': desc,
      'iconName': icon,
    });
  }

  // Delete Event
  Future<void> deleteEvent(String id) async {
    await _eventsCollection.doc(id).delete();
  }

  // ==========================================
  // APPOINTMENTS
  // ==========================================
  final CollectionReference _appointmentsCollection = FirebaseFirestore.instance
      .collection('appointments');

  // Add Appointment (For Users)
  Future<void> addAppointment(
    String clinic,
    String doctor,
    String date,
    String time,
    String pet,
    String type,
    String userId,
    String userName,
    String userEmail,
    String additionalInfo,
    String consultationMethod,
  ) async {
    await _appointmentsCollection.add({
      'clinicName': clinic,
      'doctorName': doctor,
      'date': date,
      'time': time,
      'petName': pet,
      'visitType': type,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'additionalInfo': additionalInfo,
      'consultationMethod': consultationMethod,
      'status': 'Pending',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Count active bookings (Pending or Confirmed) for a user
  Future<int> getActiveBookingCount(String userId) async {
    final query = await _appointmentsCollection
        .where('userId', isEqualTo: userId)
        .get();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return query.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();
      final dateStr = (data['date'] ?? '').toString();
      try {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final d = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          if (d.isBefore(today)) return false; // Ignore past dates
        }
      } catch (_) {}
      return status == 'Pending' || status == 'Confirmed';
    }).length;
  }

  // Get Appointments Stream (For specific User)
  Stream<List<Map<String, dynamic>>> getUserAppointmentsStream(String userId) {
    return _appointmentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Include ID
            return data;
          }).toList();
        });
  }

  // Get All Appointments Stream (For Vet Dashboard)
  Stream<List<Map<String, dynamic>>> getAllAppointmentsStream() {
    return _appointmentsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Get slot status for a clinic slot (date + time)
  // Returns: 'confirmed', 'pending', or 'available'
  Future<String> getSlotStatus(
    String clinicName,
    String date,
    String time,
  ) async {
    final query = await _appointmentsCollection
        .where('clinicName', isEqualTo: clinicName)
        .where('date', isEqualTo: date)
        .where('time', isEqualTo: time)
        .get();

    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'confirmed') return 'confirmed';
      if (status == 'pending') return 'pending';
    }

    return 'available';
  }

  // Convenience: check if slot is taken. If includePending=true, treat pending as taken too.
  Future<bool> isSlotTaken(
    String clinicName,
    String date,
    String time, {
    bool includePending = false,
  }) async {
    final status = await getSlotStatus(clinicName, date, time);
    if (status == 'confirmed') return true;
    if (includePending && status == 'pending') return true;
    return false;
  }

  // Delete Appointment
  Future<void> deleteAppointment(String id) async {
    await _appointmentsCollection.doc(id).delete();
  }

  // ==========================================
  // PETS (Vet Managed)
  // ==========================================
  final CollectionReference _petsCollection = FirebaseFirestore.instance
      .collection('pets');

  // Add Pet (Vet Only)
  Future<void> addPet({
    required String name,
    required String species,
    required String breed,
    required String birthdate,
    required String weight,
    required String gender,
    required String color, // Added Color
    required bool isNeutered, // Added Neutered
    required String ownerEmail, // Vital for linking
    required String emoji,
    required String vetName,
  }) async {
    await _petsCollection.add({
      'name': name,
      'species': species,
      'breed': breed,
      'birthdate': birthdate,
      'weight': weight,
      'gender': gender,
      'color': color, // Save Color
      'isNeutered': isNeutered, // Save Neutered
      'ownerEmail': ownerEmail.trim().toLowerCase(), // Normalize email
      'emoji': emoji,
      'vetName': vetName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Pet
  Future<void> updatePet(
    String id, {
    required String name,
    required String breed,
    required String birthdate,
    required String weight,
    required String color,
    required bool isNeutered,
    required String emoji,
    String? notes,
  }) async {
    await _petsCollection.doc(id).update({
      'name': name,
      'breed': breed,
      'birthdate': birthdate,
      'weight': weight,
      'color': color,
      'isNeutered': isNeutered,
      'emoji': emoji,
      if (notes != null) 'notes': notes,
    });
  }

  // Delete Pet
  Future<void> deletePet(String id) async {
    await _petsCollection.doc(id).delete();
  }

  // Get Pets Stream (For specific User)
  Stream<List<Map<String, dynamic>>> getUserPetsStream(String ownerEmail) {
    return _petsCollection
        .where('ownerEmail', isEqualTo: ownerEmail.trim().toLowerCase())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Get All Pets (For Vet Dashboard)
  Stream<List<Map<String, dynamic>>> getAllPetsStream() {
    return _petsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // ==========================================
  // USERS (For Vet Selector)
  // ==========================================
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Save User Profile (Call this on SignUp)
  Future<void> saveUser(
    String uid,
    String email,
    String name,
    String role,
  ) async {
    await _usersCollection.doc(uid).set(
      {
        'email': email.toLowerCase(),
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    ); // Ensure we don't accidentally wipe phone/address if syncing
  }

  // Update User Contact Details
  Future<void> updateUserContactDetails(
    String uid,
    String name,
    String phone,
    String address,
  ) async {
    await _usersCollection.doc(uid).set({
      'name': name,
      'phone': phone,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get User Profile Stream
  Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return _usersCollection.doc(uid).snapshots();
  }

  // Get All Owners (For Vet "Add Pet" Selector)
  Stream<List<Map<String, dynamic>>> getOwnersStream() {
    // FIX: Removing the strict 'role == owner' filter because previously created
    // accounts might not have this exact role string, causing the list to be empty.
    return _usersCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ==========================================
  // PET REQUESTS (Changes/Deletions)
  // ==========================================
  final CollectionReference _petRequestsCollection = FirebaseFirestore.instance
      .collection('pet_requests');

  Future<void> addPetRequest({
    required String petId,
    required String petName,
    required String ownerId,
    required String ownerEmail,
    required String requestType,
    required String reason,
  }) async {
    await _petRequestsCollection.add({
      'petId': petId,
      'petName': petName,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail.toLowerCase(),
      'requestType': requestType,
      'reason': reason,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Pet Requests Stream (For Vet Dashboard)
  Stream<List<Map<String, dynamic>>> getPetRequestsStream() {
    return _petRequestsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Update Pet Request Status
  Future<void> updatePetRequestStatus(
    String requestId,
    String status,
    String vetReply,
  ) async {
    await _petRequestsCollection.doc(requestId).update({
      'status': status,
      'vetReply': vetReply,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Pet Requests for a specific Owner
  Stream<List<Map<String, dynamic>>> getPetRequestsForOwnerStream(
    String ownerId,
  ) {
    return _petRequestsCollection
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList(),
        );
  }

  // Delete Pet Request (For Vet)
  Future<void> deletePetRequest(String requestId) async {
    await _petRequestsCollection.doc(requestId).delete();
  }

  // ==========================================
  // DASHBOARD QUICK STATS (NEW)
  // ==========================================

  // Get count of Pending Appointments
  Stream<int> getPendingAppointmentsCountStream() {
    return _appointmentsCollection
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isRead'] == false;
          }).length,
        );
  }

  // Get Cancelled Appointments Count Stream (For Vet notification)
  Stream<int> getCancelledAppointmentsCountStream() {
    return _appointmentsCollection
        .where('status', isEqualTo: 'Cancelled')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark Pending Appointments as Read
  Future<void> markAppointmentsAsRead() async {
    final query = await _appointmentsCollection
        .where('status', isEqualTo: 'Pending')
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isRead'] == false) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  // Get count of Pending Requests
  Stream<int> getPendingRequestsCountStream() {
    return _petRequestsCollection
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get count of Today's Appointments
  Stream<int> getTodayAppointmentsCountStream() {
    final now = DateTime.now();
    final todayString =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    return _appointmentsCollection
        .where('date', isEqualTo: todayString)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Total unread messages for the vet across all chat threads
  Stream<int> getVetUnreadCountStream() {
    return _chatsCollection.snapshots().map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += ((data['unreadByVet'] ?? 0) as num).toInt();
      }
      return total;
    });
  }

  // ==========================================
  // CLINIC SETTINGS
  // ==========================================
  final CollectionReference _settingsCollection = FirebaseFirestore.instance
      .collection('settings');

  Future<void> updateClinicSettings({
    required String phone,
    required String email,
    required String address,
  }) async {
    await _settingsCollection.doc('clinic_profile').set({
      'phone': phone,
      'email': email,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getClinicSettingsStream() {
    return _settingsCollection.doc('clinic_profile').snapshots();
  }

  // ==========================================
  // SERVICE PRICING
  // ==========================================

  Future<Map<String, String>> getServicePrices() async {
    final doc = await _settingsCollection.doc('service_prices').get();
    if (!doc.exists || doc.data() == null) {
      // Seed with defaults
      const defaults = {
        'checkup': '500',
        'vaccination': '800',
        'grooming': '400',
        'surgery': '3000',
        'others': '500',
      };
      await _settingsCollection.doc('service_prices').set(defaults);
      return defaults;
    }
    final data = doc.data() as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v.toString()));
  }

  Stream<Map<String, String>> getServicePricesStream() {
    return _settingsCollection.doc('service_prices').snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return {
          'checkup': '500',
          'vaccination': '800',
          'grooming': '400',
          'surgery': '3000',
          'others': '500',
        };
      }
      final data = snapshot.data() as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, v.toString()));
    });
  }

  Future<void> updateServicePrices(Map<String, String> prices) async {
    await _settingsCollection.doc('service_prices').set(prices);
  }

  // ==========================================
  // MEDICAL SESSION NOTES (Checkup History)
  // ==========================================

  // Add a new session note to a specific pet
  Future<void> addSessionNote({
    required String petId,
    required String vetName,
    required String note,
    DateTime? customDate,
  }) async {
    await _petsCollection.doc(petId).collection('session_notes').add({
      'vetName': vetName,
      'note': note,
      'createdAt': customDate != null
          ? Timestamp.fromDate(customDate)
          : FieldValue.serverTimestamp(),
    });
  }

  // Get stream of session notes for a specific pet
  Stream<List<Map<String, dynamic>>> getSessionNotesStream(String petId) {
    return _petsCollection
        .doc(petId)
        .collection('session_notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // ==========================================
  // CHAT SYSTEM
  // ==========================================
  final CollectionReference _chatsCollection = FirebaseFirestore.instance
      .collection('chats');

  // Send a message
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String text,
    required bool isVetSender,
    required String chatId, // This is usually the user's ID
    required String chatUserName,
  }) async {
    final chatDoc = _chatsCollection.doc(chatId);

    // 1. Add message to subcollection
    await chatDoc.collection('messages').add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'isVetSender': isVetSender,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Update chat metadata
    await chatDoc.set({
      'userId': chatId,
      'userName': chatUserName,
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadByVet': isVetSender ? 0 : FieldValue.increment(1),
      'unreadByUser': isVetSender ? FieldValue.increment(1) : 0,
    }, SetOptions(merge: true));
  }

  // Get Messages Stream Builder
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Get active chats for Vet Inbox
  Stream<List<Map<String, dynamic>>> getVetInboxStream() {
    return _chatsCollection
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Get active chats for User (Optional, could just check unreadByUser)
  Stream<DocumentSnapshot> getUserChatStream(String chatId) {
    return _chatsCollection.doc(chatId).snapshots();
  }

  Stream<int> getUserUnreadCountStream(String userId) {
    return _chatsCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return 0;
      final data = snapshot.data() as Map<String, dynamic>;
      return ((data['unreadByUser'] ?? 0) as num).toInt();
    });
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId, bool isVet) async {
    final chatDoc = _chatsCollection.doc(chatId);
    await chatDoc.set({
      isVet ? 'unreadByVet' : 'unreadByUser': 0,
    }, SetOptions(merge: true));
  }

  // ==========================================
  // VET AVAILABILITY
  // ==========================================
  final CollectionReference _availabilityCollection = FirebaseFirestore.instance
      .collection('vet_availability');

  Future<void> toggleAvailability(
    String dateString,
    String timeSlot,
    bool makeAvailable,
  ) async {
    final docRef = _availabilityCollection.doc(dateString);
    if (makeAvailable) {
      await docRef.set({
        'slots': FieldValue.arrayUnion([timeSlot]),
      }, SetOptions(merge: true));
    } else {
      await docRef.set({
        'slots': FieldValue.arrayRemove([timeSlot]),
      }, SetOptions(merge: true));
    }
  }

  Future<void> setAllAvailability(String dateString, List<String> slots) async {
    final docRef = _availabilityCollection.doc(dateString);
    await docRef.set({'slots': slots}, SetOptions(merge: true));
  }

  Stream<List<String>> getAvailableTimesStream(String dateString) {
    return _availabilityCollection.doc(dateString).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return [];
      final data = snapshot.data() as Map<String, dynamic>;
      final list = data['slots'] as List<dynamic>? ?? [];
      return list.map((e) => e.toString()).toList();
    });
  }

  Future<List<String>> getAvailableTimes(String dateString) async {
    final snapshot = await _availabilityCollection.doc(dateString).get();
    if (!snapshot.exists || snapshot.data() == null) return [];
    final data = snapshot.data() as Map<String, dynamic>;
    final list = data['slots'] as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }
}
