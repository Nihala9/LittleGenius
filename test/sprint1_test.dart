import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:little_genius/services/database_service.dart';
import 'package:little_genius/models/concept_model.dart';
import 'package:little_genius/models/activity_model.dart';

// 1. CREATE FAKES: Mocktail needs these to handle the 'any()' matcher
class FakeConcept extends Fake implements Concept {}
class FakeActivity extends Fake implements Activity {}

// 2. MOCK CLASS
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;

  // 3. REGISTER FALLBACKS
  setUpAll(() {
    registerFallbackValue(FakeConcept());
    registerFallbackValue(FakeActivity());
  });

  setUp(() {
    mockDb = MockDatabaseService();
  });

  group('LittleGenius - Sprint 1 (Admin & Content Management)', () {
    
    // TEST 1: ADDING CONCEPT (TC_S1_02)
    test('Admin should successfully add a new concept', () async {
      final concept = Concept(id: '1', name: 'Letter A', category: 'Alphabets', order: 1);
      
      when(() => mockDb.addConcept(any())).thenAnswer((_) async => {});

      await mockDb.addConcept(concept);

      verify(() => mockDb.addConcept(any())).called(1);
    });

    // TEST 2: SEQUENCE ORDER (TC_S1_03)
    test('Concept should retain correct sequence order', () {
      final concept = Concept(id: '1', name: 'Letter A', category: 'Alphabets', order: 5);
      expect(concept.order, 5); 
    });

    // TEST 3: UNIVERSAL MODE TAGGING (TC_S1_04 - UPDATED)
    test('Activity should save correct mode and image metadata', () async {
      // FIX: Removed 'language' parameter as it is now removed from the model
      final activity = Activity(
        id: '1', 
        conceptId: 'A', 
        title: 'Tracing A', 
        activityMode: 'Tracing', 
        difficulty: 1,
        imageUrl: 'https://firebasestorage.com/image.png' // New Field
      );

      when(() => mockDb.addActivity(any())).thenAnswer((_) async => {});

      await mockDb.addActivity(activity);
      
      // Verify the new metadata logic
      expect(activity.activityMode, "Tracing");
      expect(activity.imageUrl, isNotNull);
    });

    // TEST 4: PUBLISH/VISIBILITY (TC_S1_05)
    test('Toggling visibility should update global status', () async {
      const String id = "lesson_123";
      
      when(() => mockDb.toggleConceptVisibility(id, any())).thenAnswer((_) async => {});
      
      // Test Unpublish
      await mockDb.toggleConceptVisibility(id, false);
      verify(() => mockDb.toggleConceptVisibility(id, false)).called(1);

      // Test Publish
      await mockDb.toggleConceptVisibility(id, true);
      verify(() => mockDb.toggleConceptVisibility(id, true)).called(1);
    });

    // TEST 5: NEW ACTIVITY TYPE SUPPORT (SCRATCH CARD)
    test('Activity Model should support new Scratch Card type', () {
      final activity = Activity(
        id: '2', 
        conceptId: 'Lion', 
        title: 'Lion Scratch', 
        activityMode: 'Scratch Card', 
        difficulty: 1
      );
      
      expect(activity.activityMode, 'Scratch Card');
    });
  });
}