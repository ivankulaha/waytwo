import { ActionSheetIOS, Alert, Platform } from 'react-native';
import type { TFunction } from 'i18next';

export type OnboardingGender = 'male' | 'female' | 'other';

export function presentGenderPicker(t: TFunction, onPick: (g: OnboardingGender) => void): void {
  const male = t('onboarding.you.genderMale');
  const female = t('onboarding.you.genderFemale');
  const other = t('onboarding.you.genderOther');
  const cancel = t('common.cancel');

  if (Platform.OS === 'ios') {
    const options = [male, female, other, cancel];
    ActionSheetIOS.showActionSheetWithOptions(
      { options, cancelButtonIndex: 3, userInterfaceStyle: 'dark' },
      (index) => {
        if (index === 0) onPick('male');
        else if (index === 1) onPick('female');
        else if (index === 2) onPick('other');
      },
    );
  } else {
    Alert.alert(t('onboarding.you.genderLabel'), undefined, [
      { text: male, onPress: () => onPick('male') },
      { text: female, onPress: () => onPick('female') },
      { text: other, onPress: () => onPick('other') },
      { text: cancel, style: 'cancel' },
    ]);
  }
}
