/**
 * TODO(legacy-template): Demo / template tab — remove when the new home screen is designed.
 * Header colors and layout offsets are local to this file so they never leak into AppColors.
 */
import { Image } from 'expo-image';
import { Platform, StyleSheet } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Collapsible } from '@/components/ui/collapsible';
import { ExternalLink } from '@/components/external-link';
import ParallaxScrollView from '@/components/parallax-scroll-view';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { IconSymbol } from '@/components/ui/icon-symbol';
import { Fonts } from '@/constants/theme';
import { IconSize, LayoutOffset, Size, Spacing } from '@/constants/tokens';

const TEMPORARY_EXPLORE_HEADER = {
  headerBackground: { light: '#D0D0D0', dark: '#353636' } as const,
  headerIcon: '#808080',
} as const;

const exploreTemplateRefs = {
  pathHome: 'app/(tabs)/index.tsx',
  pathExplore: 'app/(tabs)/explore.tsx',
  pathLayout: 'app/(tabs)/_layout.tsx',
  pathHelloWave: 'components/HelloWave.tsx',
  pathParallax: 'components/ParallaxScrollView.tsx',
  imageSuffix2x: '@2x',
  imageSuffix3x: '@3x',
  colorSchemeHook: 'useColorScheme()',
} as const;

export default function TabTwoScreen() {
  const { t } = useTranslation();

  return (
    <ParallaxScrollView
      headerBackgroundColor={{
        light: TEMPORARY_EXPLORE_HEADER.headerBackground.light,
        dark: TEMPORARY_EXPLORE_HEADER.headerBackground.dark,
      }}
      headerImage={
        <IconSymbol
          size={IconSize.hero}
          color={TEMPORARY_EXPLORE_HEADER.headerIcon}
          name="chevron.left.forwardslash.chevron.right"
          style={styles.headerImage}
        />
      }>
      <ThemedView style={styles.titleContainer}>
        <ThemedText
          type="title"
          style={{
            fontFamily: Fonts.rounded,
          }}>
          {t('explore.title')}
        </ThemedText>
      </ThemedView>
      <ThemedText>{t('explore.intro')}</ThemedText>
      <Collapsible title={t('explore.collapsible.routing')}>
        <ThemedText>
          {t('explore.collapsible.routingBody1')}{' '}
          <ThemedText type="defaultSemiBold">{exploreTemplateRefs.pathHome}</ThemedText>{' '}
          {t('explore.collapsible.routingBody2')}{' '}
          <ThemedText type="defaultSemiBold">{exploreTemplateRefs.pathExplore}</ThemedText>
        </ThemedText>
        <ThemedText>
          {t('explore.collapsible.routingBody3')}{' '}
          <ThemedText type="defaultSemiBold">{exploreTemplateRefs.pathLayout}</ThemedText>{' '}
          {t('explore.collapsible.routingBody4')}
        </ThemedText>
        <ExternalLink href="https://docs.expo.dev/router/introduction">
          <ThemedText type="link">{t('explore.learnMore')}</ThemedText>
        </ExternalLink>
      </Collapsible>
      <Collapsible title={t('explore.collapsible.platforms')}>
        <ThemedText>
          {t('explore.collapsible.platformsBody')}{' '}
          <ThemedText type="defaultSemiBold">{t('explore.collapsible.platformsBodyKey')}</ThemedText>{' '}
          {t('explore.collapsible.platformsBodySuffix')}
        </ThemedText>
      </Collapsible>
      <Collapsible title={t('explore.collapsible.images')}>
        <ThemedText>
          {t('explore.collapsible.imagesBody')}{' '}
          <ThemedText type="defaultSemiBold">{exploreTemplateRefs.imageSuffix2x}</ThemedText>{' '}
          {t('explore.collapsible.routingBody2')}{' '}
          <ThemedText type="defaultSemiBold">{exploreTemplateRefs.imageSuffix3x}</ThemedText>{' '}
          {t('explore.collapsible.imagesBodySuffix')}
        </ThemedText>
        <Image
          source={require('@/assets/images/react-logo.png')}
          style={{ width: Size.demoImage, height: Size.demoImage, alignSelf: 'center' }}
        />
        <ExternalLink href="https://reactnative.dev/docs/images">
          <ThemedText type="link">{t('explore.learnMore')}</ThemedText>
        </ExternalLink>
      </Collapsible>
      <Collapsible title={t('explore.collapsible.theming')}>
        <ThemedText>
          {t('explore.collapsible.themingBody')}{' '}
          <ThemedText type="defaultSemiBold">{exploreTemplateRefs.colorSchemeHook}</ThemedText>{' '}
          {t('explore.collapsible.themingBodyHook')}
        </ThemedText>
        <ExternalLink href="https://docs.expo.dev/develop/user-interface/color-themes/">
          <ThemedText type="link">{t('explore.learnMore')}</ThemedText>
        </ExternalLink>
      </Collapsible>
      <Collapsible title={t('explore.collapsible.animations')}>
        <ThemedText>
          {t('explore.collapsible.animationsBody')}{' '}
          <ThemedText type="defaultSemiBold">{exploreTemplateRefs.pathHelloWave}</ThemedText>{' '}
          {t('explore.collapsible.animationsBodyMid')}{' '}
          <ThemedText type="defaultSemiBold" style={{ fontFamily: Fonts.mono }}>
            react-native-reanimated
          </ThemedText>{' '}
          {t('explore.collapsible.animationsBodyLib')}
        </ThemedText>
        {Platform.select({
          ios: (
            <ThemedText>
              {t('explore.collapsible.animationsBodyIos')}{' '}
              <ThemedText type="defaultSemiBold">{exploreTemplateRefs.pathParallax}</ThemedText>{' '}
              {t('explore.collapsible.animationsBodyIosMid')}
            </ThemedText>
          ),
        })}
      </Collapsible>
    </ParallaxScrollView>
  );
}

const styles = StyleSheet.create({
  headerImage: {
    color: TEMPORARY_EXPLORE_HEADER.headerIcon,
    bottom: LayoutOffset.exploreHeaderImageBottom,
    left: LayoutOffset.exploreHeaderImageLeft,
    position: 'absolute',
  },
  titleContainer: {
    flexDirection: 'row',
    gap: Spacing.md,
  },
});
