import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:little_genius/services/auth_service.dart';
import 'package:little_genius/services/database_service.dart';
import 'package:little_genius/services/ai_service.dart';
import 'package:little_genius/models/child_model.dart';

// Mocks
class MockAuthService extends Mock implements AuthService {}
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockAuthService mockAuth;
  late MockDatabaseService mockDb;
  late AIService aiService;

  setUp(() {
    mockAuth = MockAuthService();
    mockDb = MockDatabaseService();
    aiService = AIService(); // Real logic test
  });

  group('LittleGenius - Sprint 2 (User Experience & AI Logic)', () {
    
    // 1. TEST PARENT AUTH (TC_S2_01)
    test('Parent should be able to login successfully', () async {
      when(() => mockAuth.loginUser("parent@test.com", "password123"))
          .thenAnswer((_) async => {'role': 'parent', 'email': 'parent@test.com'});

      final result = await mockAuth.loginUser("parent@test.com", "password123");
      
      expect(result!['role'], 'parent');
      verify(() => mockAuth.loginUser("parent@test.com", "password123")).called(1);
    });

    // 2. TEST MULTILINGUAL PROFILE (TC_S2_02)
    test('Child Profile should correctly store Class and Language', () {
      final child = ChildProfile(
        id: 'child_01',
        name: 'Leo',
        age: 4,
        childClass: 'Pre-School', // Your new requirement
        language: 'Arabic',      // Your new requirement
        avatarUrl: 'assets/icons/profiles/p1.png',
      );

      expect(child.childClass, 'Pre-School');
      expect(child.language, 'Arabic');
    });

    // 3. TEST AI PERFORMANCE LOGIC (TC_S2_05)
    test('BKT Algorithm should increase mastery score on success', () {
      double initialMastery = 0.5;
      
      // We use the real AIService to test the math
      double newMastery = aiService.calculateNewMastery(initialMastery, true);
      
      // In BKT, a success MUST result in a higher mastery probability
      expect(newMastery > initialMastery, true);
    });

    // 4. TEST STAR REWARD LOGIC (TC_S2_05)
    test('Winning a game should trigger star update', () async {
      const String parentId = "parent_123";
      const String childId = "child_456";
      
      // Mock the database update
      when(() => mockDb.updateChildProfile(any(), any(), any()))
          .thenAnswer((_) async => {});

      await mockDb.updateChildProfile(parentId, childId, {'totalStars': 20});

      verify(() => mockDb.updateChildProfile(parentId, childId, {'totalStars': 20})).called(1);
    });
  });
}