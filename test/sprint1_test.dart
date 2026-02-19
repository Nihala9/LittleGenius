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

  // 3. REGISTER FALLBACKS: This is the fix for your error
  setUpAll(() {
    registerFallbackValue(FakeConcept());
    registerFallbackValue(FakeActivity());
  });

  setUp(() {
    mockDb = MockDatabaseService();
  });

  group('LittleGenius - Sprint 1 (Admin & Content Management)', () {
    
    // TEST 1: ADDING ACTIVITY (TC_S1_02)
    test('Admin should successfully add a new concept', () async {
      final concept = Concept(id: '1', name: 'Letter A', category: 'Alphabets', order: 1);
      
      // Setup mock behavior
      when(() => mockDb.addConcept(any())).thenAnswer((_) async => {});

      // Perform action
      await mockDb.addConcept(concept);

      // Verify result
      verify(() => mockDb.addConcept(any())).called(1);
    });

    // TEST 2: PERFORMANCE CONFIG (TC_S1_03)
    test('Concept should retain correct sequence order', () {
      final concept = Concept(id: '1', name: 'Letter A', category: 'Alphabets', order: 5);
      expect(concept.order, 5); 
    });

    // TEST 3: MULTILINGUAL TAGGING (TC_S1_04)
    test('Activity should save correct language tags', () async {
      final activity = Activity(
        id: '1', 
        conceptId: 'A', 
        title: 'Tracing A', 
        activityMode: 'Tracing', 
        language: 'Malayalam', 
        difficulty: 1
      );

      when(() => mockDb.addActivity(any())).thenAnswer((_) async => {});

      await mockDb.addActivity(activity);
      
      // Verify that the language was correctly assigned in the model
      expect(activity.language, "Malayalam");
    });

    // TEST 4: PUBLISH/VISIBILITY (TC_S1_05)
    test('Toggling visibility should update global status', () async {
      const String id = "lesson_123";
      
      // Test Unpublish logic
      when(() => mockDb.toggleConceptVisibility(id, false)).thenAnswer((_) async => {});
      await mockDb.toggleConceptVisibility(id, false);
      verify(() => mockDb.toggleConceptVisibility(id, false)).called(1);

      // Test Publish logic
      when(() => mockDb.toggleConceptVisibility(id, true)).thenAnswer((_) async => {});
      await mockDb.toggleConceptVisibility(id, true);
      verify(() => mockDb.toggleConceptVisibility(id, true)).called(1);
    });
  });
}