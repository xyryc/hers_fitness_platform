import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/services/member_assessment_service.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';

class AssessmentController extends GetxController {
  AssessmentController({MemberAssessmentService? assessmentService})
    : _assessmentService = assessmentService ?? MemberAssessmentService();

  final MemberAssessmentService _assessmentService;

  static const List<String> goalOptions = [
    'LOSE_WEIGHT',
    'GAIN_BULK',
    'GAIN_ENDURANCE',
    'TRYING_OUT_APP',
  ];

  static const List<String> dietOptions = [
    'PLANT_BASED_VEGAN',
    'CARBO_DIET',
    'SPECIALIZED_PALEO_KETO',
    'TRADITIONAL_FRUIT_DIET',
  ];

  static const List<String> sleepQualityOptions = [
    'EXCELLENT',
    'GREAT',
    'NORMAL',
    'BAD',
    'INSOMNIAC',
  ];

  static const Map<String, String> supplementValues = {
    'Whey': 'WHEY',
    'Protein': 'PROTEIN',
    'Vitamin D': 'VITAMIN_D',
    'Magnesium': 'MAGNESIUM',
  };

  // Goal selection
  var selectedGoalIndex = (-1).obs;

  // Weight selection
  var weight = 128.0.obs;
  var weightUnit = 'kg'.obs; // 'kg' or 'lbs'

  // Age selection
  var age = 18.obs;

  // Fitness experience
  var hasExperience = false.obs;

  // Physical limitations
  var limitations = <String>[].obs;

  // Diet preference
  var selectedDietIndex = (-1).obs;

  // Supplements
  var takingSupplements = false.obs;
  var selectedSupplements = <String>[].obs;

  // Calorie goal
  var calorieGoal = 1550.obs;
  var calorieUnit = 'Kcal'.obs; // 'Kcal' or 'Joule's'

  // Sleep quality
  var selectedSleepIndex = (-1).obs;

  final isSubmitting = false.obs;

  void setGoal(int index) {
    selectedGoalIndex.value = index;
  }

  void setWeight(double value) {
    weight.value = value;
  }

  void setWeightUnit(String unit) {
    weightUnit.value = unit;
  }

  void setAge(int value) {
    age.value = value;
  }

  void setExperience(bool value) {
    hasExperience.value = value;
  }

  void addLimitation(String value) {
    if (limitations.length < 10 &&
        value.isNotEmpty &&
        !limitations.contains(value)) {
      limitations.add(value);
    }
  }

  void removeLimitation(String value) {
    limitations.remove(value);
  }

  void setDietPreference(int index) {
    selectedDietIndex.value = index;
  }

  void setTakingSupplements(bool value) {
    takingSupplements.value = value;
  }

  void toggleSupplement(String supplement) {
    if (selectedSupplements.contains(supplement)) {
      selectedSupplements.remove(supplement);
    } else {
      selectedSupplements.add(supplement);
    }
  }

  void setCalorieGoal(int value) {
    calorieGoal.value = value;
  }

  void setCalorieUnit(String unit) {
    calorieUnit.value = unit;
  }

  void setSleepQuality(int index) {
    selectedSleepIndex.value = index;
  }

  Future<bool> submitAssessment() async {
    final validationMessage = _validateSubmission();
    if (validationMessage != null) {
      showAppSnackbar(
        'Assessment incomplete',
        validationMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isSubmitting.value = true;
      await _assessmentService.updateAssessment(toRequestBody());
      return true;
    } on ApiException catch (error) {
      showAppSnackbar(
        'Assessment failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (_) {
      showAppSnackbar(
        'Assessment failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Map<String, dynamic> toRequestBody() {
    final body = <String, dynamic>{
      'fitnessGoal': _selectedValue(goalOptions, selectedGoalIndex.value),
      'weight': double.parse(weight.value.toStringAsFixed(1)),
      'weightUnit': weightUnit.value.toUpperCase(),
      'age': age.value,
      'hasPreviousFitnessExperience': hasExperience.value,
      'dietPreference': _selectedValue(dietOptions, selectedDietIndex.value),
      'takingSupplements': takingSupplements.value,
      'supplements': _selectedSupplementValues(),
      'calorieGoal': calorieGoal.value,
      'calorieUnit': calorieUnit.value == 'Kcal' ? 'KCAL' : 'JOULES',
      'sleepQuality': _selectedValue(
        sleepQualityOptions,
        selectedSleepIndex.value,
      ),
    };

    if (limitations.isNotEmpty) {
      body['physicalLimitations'] = limitations.join(', ');
    }

    return body;
  }

  String? _validateSubmission() {
    if (_selectedValue(goalOptions, selectedGoalIndex.value) == null) {
      return 'Please select your fitness goal.';
    }

    if (_selectedValue(dietOptions, selectedDietIndex.value) == null) {
      return 'Please select your diet preference.';
    }

    if (takingSupplements.value && _selectedSupplementValues().isEmpty) {
      return 'Please select your supplements or go back and choose No.';
    }

    if (_selectedValue(sleepQualityOptions, selectedSleepIndex.value) == null) {
      return 'Please select your sleep quality.';
    }

    return null;
  }

  String? _selectedValue(List<String> options, int index) {
    if (index < 0 || index >= options.length) return null;
    return options[index];
  }

  List<String> _selectedSupplementValues() {
    if (!takingSupplements.value) return <String>[];

    return selectedSupplements
        .map((supplement) => supplementValues[supplement])
        .whereType<String>()
        .toSet()
        .toList();
  }
}
