import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @commonAppName.
  ///
  /// In en, this message translates to:
  /// **'Lumen'**
  String get commonAppName;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get commonFailed;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get commonJustNow;

  /// No description provided for @commonMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **' minutes ago'**
  String get commonMinutesAgo;

  /// No description provided for @commonHoursAgo.
  ///
  /// In en, this message translates to:
  /// **' hours ago'**
  String get commonHoursAgo;

  /// No description provided for @commonDaysAgo.
  ///
  /// In en, this message translates to:
  /// **' days ago'**
  String get commonDaysAgo;

  /// No description provided for @commonMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **' months ago'**
  String get commonMonthsAgo;

  /// No description provided for @commonYearsAgo.
  ///
  /// In en, this message translates to:
  /// **' years ago'**
  String get commonYearsAgo;

  /// No description provided for @commonBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get commonBackToHome;

  /// No description provided for @commonAppTagline.
  ///
  /// In en, this message translates to:
  /// **'Enterprise Flutter Scaffold'**
  String get commonAppTagline;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get commonOr;

  /// No description provided for @validationUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get validationUsernameRequired;

  /// No description provided for @validationUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get validationUsernameTooShort;

  /// No description provided for @validationUsernameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Username must be less than 20 characters'**
  String get validationUsernameTooLong;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validationPasswordTooShort;

  /// No description provided for @validationPasswordTooLong.
  ///
  /// In en, this message translates to:
  /// **'Password must be less than 20 characters'**
  String get validationPasswordTooLong;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordMismatch;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validationEmailInvalid;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get validationPhoneInvalid;

  /// No description provided for @pagesLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get pagesLoginTitle;

  /// No description provided for @pagesLoginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get pagesLoginWelcome;

  /// No description provided for @pagesLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please login to continue'**
  String get pagesLoginSubtitle;

  /// No description provided for @pagesLoginUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get pagesLoginUsername;

  /// No description provided for @pagesLoginUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get pagesLoginUsernameHint;

  /// No description provided for @pagesLoginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get pagesLoginPassword;

  /// No description provided for @pagesLoginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get pagesLoginPasswordHint;

  /// No description provided for @pagesLoginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get pagesLoginSubmit;

  /// No description provided for @pagesLoginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get pagesLoginNoAccount;

  /// No description provided for @pagesLoginGoRegister.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get pagesLoginGoRegister;

  /// No description provided for @pagesLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get pagesLoginSuccess;

  /// No description provided for @pagesLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get pagesLoginFailed;

  /// No description provided for @pagesRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get pagesRegisterTitle;

  /// No description provided for @pagesRegisterWelcome.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get pagesRegisterWelcome;

  /// No description provided for @pagesRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get pagesRegisterSubtitle;

  /// No description provided for @pagesRegisterUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get pagesRegisterUsername;

  /// No description provided for @pagesRegisterUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get pagesRegisterUsernameHint;

  /// No description provided for @pagesRegisterEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get pagesRegisterEmail;

  /// No description provided for @pagesRegisterEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email (optional)'**
  String get pagesRegisterEmailHint;

  /// No description provided for @pagesRegisterPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get pagesRegisterPassword;

  /// No description provided for @pagesRegisterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get pagesRegisterPasswordHint;

  /// No description provided for @pagesRegisterConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get pagesRegisterConfirmPassword;

  /// No description provided for @pagesRegisterConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password again'**
  String get pagesRegisterConfirmPasswordHint;

  /// No description provided for @pagesRegisterSubmit.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get pagesRegisterSubmit;

  /// No description provided for @pagesRegisterHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get pagesRegisterHaveAccount;

  /// No description provided for @pagesRegisterGoLogin.
  ///
  /// In en, this message translates to:
  /// **'Login Now'**
  String get pagesRegisterGoLogin;

  /// No description provided for @pagesRegisterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get pagesRegisterSuccess;

  /// No description provided for @pagesRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get pagesRegisterFailed;

  /// No description provided for @pagesHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get pagesHomeTitle;

  /// No description provided for @pagesHomeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Lumen!'**
  String get pagesHomeWelcome;

  /// No description provided for @pagesHomeIntro.
  ///
  /// In en, this message translates to:
  /// **'A powerful Flutter scaffold for rapid development'**
  String get pagesHomeIntro;

  /// No description provided for @pagesHomeQuickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get pagesHomeQuickStart;

  /// No description provided for @pagesHomeViewDocs.
  ///
  /// In en, this message translates to:
  /// **'View Documentation'**
  String get pagesHomeViewDocs;

  /// No description provided for @pagesHomeViewDocsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn about the project architecture'**
  String get pagesHomeViewDocsSubtitle;

  /// No description provided for @pagesHomeSubmitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get pagesHomeSubmitFeedback;

  /// No description provided for @pagesHomeSubmitFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report issues or suggestions'**
  String get pagesHomeSubmitFeedbackSubtitle;

  /// No description provided for @pagesHomeGiveStar.
  ///
  /// In en, this message translates to:
  /// **'Give a Star'**
  String get pagesHomeGiveStar;

  /// No description provided for @pagesHomeGiveStarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Support open source'**
  String get pagesHomeGiveStarSubtitle;

  /// No description provided for @pagesHomeFeatureGetxDesc.
  ///
  /// In en, this message translates to:
  /// **'State Management'**
  String get pagesHomeFeatureGetxDesc;

  /// No description provided for @pagesHomeFeatureRouterDesc.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get pagesHomeFeatureRouterDesc;

  /// No description provided for @pagesHomeFeatureHiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Local Storage'**
  String get pagesHomeFeatureHiveDesc;

  /// No description provided for @pagesHomeFeatureI18nDesc.
  ///
  /// In en, this message translates to:
  /// **'Localization'**
  String get pagesHomeFeatureI18nDesc;

  /// No description provided for @pagesHomeFeatureThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Theme System'**
  String get pagesHomeFeatureThemeDesc;

  /// No description provided for @pagesHomeFeatureFreezedDesc.
  ///
  /// In en, this message translates to:
  /// **'Data Models'**
  String get pagesHomeFeatureFreezedDesc;

  /// No description provided for @pagesProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get pagesProfileTitle;

  /// No description provided for @pagesProfileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get pagesProfileEmail;

  /// No description provided for @pagesProfileJoinDate.
  ///
  /// In en, this message translates to:
  /// **'Join Date'**
  String get pagesProfileJoinDate;

  /// No description provided for @pagesProfileAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get pagesProfileAccountStatus;

  /// No description provided for @pagesProfileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get pagesProfileVerified;

  /// No description provided for @pagesSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get pagesSettingsTitle;

  /// No description provided for @pagesSettingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get pagesSettingsTheme;

  /// No description provided for @pagesSettingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get pagesSettingsLanguage;

  /// No description provided for @pagesSettingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get pagesSettingsAbout;

  /// No description provided for @pagesSettingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get pagesSettingsLogout;

  /// No description provided for @pagesSettingsLogoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get pagesSettingsLogoutSuccess;

  /// No description provided for @pagesSettingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get pagesSettingsLogoutConfirm;

  /// No description provided for @pagesSettingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get pagesSettingsDarkMode;

  /// No description provided for @pagesSettingsLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get pagesSettingsLightMode;

  /// No description provided for @pagesSettingsSystemMode.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get pagesSettingsSystemMode;

  /// No description provided for @pagesSettingsChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get pagesSettingsChinese;

  /// No description provided for @pagesSettingsEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get pagesSettingsEnglish;

  /// No description provided for @pagesSettingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get pagesSettingsVersion;

  /// No description provided for @pagesSettingsAboutDesc.
  ///
  /// In en, this message translates to:
  /// **'A powerful Flutter enterprise scaffold'**
  String get pagesSettingsAboutDesc;

  /// No description provided for @pagesNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pagesNotFoundTitle;

  /// No description provided for @pagesNotFoundCode.
  ///
  /// In en, this message translates to:
  /// **'404'**
  String get pagesNotFoundCode;

  /// No description provided for @pagesNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist'**
  String get pagesNotFoundMessage;

  /// No description provided for @pagesNotFoundBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get pagesNotFoundBackHome;

  /// No description provided for @widgetsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get widgetsErrorTitle;

  /// No description provided for @widgetsErrorNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get widgetsErrorNetworkTitle;

  /// No description provided for @widgetsErrorNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your network settings'**
  String get widgetsErrorNetworkMessage;

  /// No description provided for @widgetsErrorServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Error'**
  String get widgetsErrorServerTitle;

  /// No description provided for @widgetsErrorServerMessage.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable, please try again later'**
  String get widgetsErrorServerMessage;

  /// No description provided for @widgetsErrorLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Load Failed'**
  String get widgetsErrorLoadFailedTitle;

  /// No description provided for @widgetsErrorUnauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Logged In'**
  String get widgetsErrorUnauthorizedTitle;

  /// No description provided for @widgetsErrorUnauthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'Please login to continue'**
  String get widgetsErrorUnauthorizedMessage;

  /// No description provided for @widgetsErrorUnauthorizedAction.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get widgetsErrorUnauthorizedAction;

  /// No description provided for @widgetsErrorForbiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get widgetsErrorForbiddenTitle;

  /// No description provided for @widgetsErrorForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this content'**
  String get widgetsErrorForbiddenMessage;

  /// No description provided for @widgetsErrorNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get widgetsErrorNotFoundTitle;

  /// No description provided for @widgetsErrorNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist or has been deleted'**
  String get widgetsErrorNotFoundMessage;

  /// No description provided for @widgetsErrorTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Timeout'**
  String get widgetsErrorTimeoutTitle;

  /// No description provided for @widgetsErrorTimeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Network response timeout, please try again'**
  String get widgetsErrorTimeoutMessage;

  /// No description provided for @widgetsEmptyNoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get widgetsEmptyNoDataTitle;

  /// No description provided for @widgetsEmptyNoSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No Results'**
  String get widgetsEmptyNoSearchTitle;

  /// No description provided for @widgetsEmptyNoSearchMessage.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{keyword}\"'**
  String widgetsEmptyNoSearchMessage(String keyword);

  /// No description provided for @widgetsEmptyNoSearchMessageDefault.
  ///
  /// In en, this message translates to:
  /// **'No related results found'**
  String get widgetsEmptyNoSearchMessageDefault;

  /// No description provided for @widgetsEmptyNoSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get widgetsEmptyNoSearchAction;

  /// No description provided for @widgetsEmptyNoNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get widgetsEmptyNoNetworkTitle;

  /// No description provided for @widgetsEmptyNoNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your network settings'**
  String get widgetsEmptyNoNetworkMessage;

  /// No description provided for @widgetsEmptyNoMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'No Messages'**
  String get widgetsEmptyNoMessageTitle;

  /// No description provided for @widgetsEmptyNoMessageMessage.
  ///
  /// In en, this message translates to:
  /// **'New messages will appear here'**
  String get widgetsEmptyNoMessageMessage;

  /// No description provided for @widgetsEmptyNoNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get widgetsEmptyNoNotificationTitle;

  /// No description provided for @widgetsEmptyNoNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'New notifications will appear here'**
  String get widgetsEmptyNoNotificationMessage;

  /// No description provided for @widgetsEmptyNoFavoriteTitle.
  ///
  /// In en, this message translates to:
  /// **'No Favorites'**
  String get widgetsEmptyNoFavoriteTitle;

  /// No description provided for @widgetsEmptyNoFavoriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Your favorites will appear here'**
  String get widgetsEmptyNoFavoriteMessage;

  /// No description provided for @widgetsEmptyNoFavoriteAction.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get widgetsEmptyNoFavoriteAction;

  /// No description provided for @widgetsListLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Pull up to load more'**
  String get widgetsListLoadMore;

  /// No description provided for @widgetsListNoMore.
  ///
  /// In en, this message translates to:
  /// **'No more data'**
  String get widgetsListNoMore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
