import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Lubok Antu RescueNet'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Emergency and Community Aid Reporting System'**
  String get appDescription;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @citizen.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get citizen;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @registerHere.
  ///
  /// In en, this message translates to:
  /// **'Register here'**
  String get registerHere;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed'**
  String get signInFailed;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @adminNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'This email is not authorized as admin'**
  String get adminNotAuthorized;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @malaysiLanguage.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get malaysiLanguage;

  /// No description provided for @citizenDashboard.
  ///
  /// In en, this message translates to:
  /// **'Citizen Dashboard'**
  String get citizenDashboard;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @rescueNet.
  ///
  /// In en, this message translates to:
  /// **'RescueNet'**
  String get rescueNet;

  /// No description provided for @loadingWeatherData.
  ///
  /// In en, this message translates to:
  /// **'Loading weather data...'**
  String get loadingWeatherData;

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReports;

  /// No description provided for @submitEmergency.
  ///
  /// In en, this message translates to:
  /// **'Submit Emergency'**
  String get submitEmergency;

  /// No description provided for @submitAidRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Aid Request'**
  String get submitAidRequest;

  /// No description provided for @viewAidRequests.
  ///
  /// In en, this message translates to:
  /// **'View Aid Requests'**
  String get viewAidRequests;

  /// No description provided for @viewAidPrograms.
  ///
  /// In en, this message translates to:
  /// **'View Aid Programs'**
  String get viewAidPrograms;

  /// No description provided for @weatherAlerts.
  ///
  /// In en, this message translates to:
  /// **'Weather Alerts'**
  String get weatherAlerts;

  /// No description provided for @aiChatbot.
  ///
  /// In en, this message translates to:
  /// **'AI Chatbot'**
  String get aiChatbot;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordHint;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginHere.
  ///
  /// In en, this message translates to:
  /// **'Login here'**
  String get loginHere;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @userAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'User already exists'**
  String get userAlreadyExists;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing'**
  String get refreshing;

  /// No description provided for @errorRefreshingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Error refreshing dashboard'**
  String get errorRefreshingDashboard;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @aidRequests.
  ///
  /// In en, this message translates to:
  /// **'Aid Requests'**
  String get aidRequests;

  /// No description provided for @aidPrograms.
  ///
  /// In en, this message translates to:
  /// **'Aid Programs'**
  String get aidPrograms;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReports;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @weatherDetails.
  ///
  /// In en, this message translates to:
  /// **'Weather Details'**
  String get weatherDetails;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @submitEmergencyReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Emergency Report'**
  String get submitEmergencyReport;

  /// No description provided for @requestAid.
  ///
  /// In en, this message translates to:
  /// **'Request Aid'**
  String get requestAid;

  /// No description provided for @mapWarnings.
  ///
  /// In en, this message translates to:
  /// **'Map Warnings'**
  String get mapWarnings;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new citizen account'**
  String get createNewAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get enterFullName;

  /// No description provided for @icNumber.
  ///
  /// In en, this message translates to:
  /// **'IC Number'**
  String get icNumber;

  /// No description provided for @enterICNumber.
  ///
  /// In en, this message translates to:
  /// **'e.g., 950123-13-5678'**
  String get enterICNumber;

  /// No description provided for @phoneNo.
  ///
  /// In en, this message translates to:
  /// **'Phone No'**
  String get phoneNo;

  /// No description provided for @enterPhoneNo.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone No'**
  String get enterPhoneNo;

  /// No description provided for @passwordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get passwordConfirm;

  /// No description provided for @enterPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get enterPasswordConfirm;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions'**
  String get agreeTerms;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @iAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Terms & Conditions'**
  String get iAgreeToTerms;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get fullNameRequired;

  /// No description provided for @icRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your IC number'**
  String get icRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get phoneRequired;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @checkAlerts.
  ///
  /// In en, this message translates to:
  /// **'Check alerts and reports in your area'**
  String get checkAlerts;

  /// No description provided for @activeReports.
  ///
  /// In en, this message translates to:
  /// **'Active Reports'**
  String get activeReports;

  /// No description provided for @newPrograms.
  ///
  /// In en, this message translates to:
  /// **'New Programs'**
  String get newPrograms;

  /// No description provided for @weatherAlert.
  ///
  /// In en, this message translates to:
  /// **'Weather Alert'**
  String get weatherAlert;

  /// No description provided for @weatherUpdate.
  ///
  /// In en, this message translates to:
  /// **'Weather Update'**
  String get weatherUpdate;

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather data unavailable'**
  String get weatherUnavailable;

  /// No description provided for @currentWeather.
  ///
  /// In en, this message translates to:
  /// **'Current Weather'**
  String get currentWeather;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @icLabel.
  ///
  /// In en, this message translates to:
  /// **'IC Number'**
  String get icLabel;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account Created'**
  String get accountCreated;

  /// No description provided for @cantBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Cannot be changed'**
  String get cantBeChanged;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @minimumCharacters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get minimumCharacters;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @reEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get reEnterPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @agreeTermsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions and Privacy Policy *'**
  String get agreeTermsPrivacy;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @emailMaxCharacters.
  ///
  /// In en, this message translates to:
  /// **'Email max is 64 characters'**
  String get emailMaxCharacters;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordMin8.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get passwordMin8;

  /// No description provided for @passwordMax20.
  ///
  /// In en, this message translates to:
  /// **'Maximum 20 characters'**
  String get passwordMax20;

  /// No description provided for @enterPassword2.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get enterPassword2;

  /// No description provided for @confirmPassword2.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPassword2;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get enterAddress;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since:'**
  String get memberSince;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @allPasswordFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All password fields are required'**
  String get allPasswordFieldsRequired;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticated;

  /// No description provided for @enterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get enterYourAddress;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordIncorrect;

  /// No description provided for @newPasswordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'New password is too weak'**
  String get newPasswordTooWeak;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorUpdatingProfile;

  /// No description provided for @errorChangingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error changing password'**
  String get errorChangingPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @reEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get reEnterNewPassword;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status:'**
  String get accountStatus;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID:'**
  String get userId;

  /// No description provided for @minimumPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get minimumPasswordLength;

  /// No description provided for @passwordMustBeAtLeast8.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMustBeAtLeast8;

  /// No description provided for @fireAlerts.
  ///
  /// In en, this message translates to:
  /// **'Fire Alerts'**
  String get fireAlerts;

  /// No description provided for @fireIncidents.
  ///
  /// In en, this message translates to:
  /// **'Fire incidents in your area'**
  String get fireIncidents;

  /// No description provided for @landslideWarnings.
  ///
  /// In en, this message translates to:
  /// **'Landslide Warnings'**
  String get landslideWarnings;

  /// No description provided for @landslideRisk.
  ///
  /// In en, this message translates to:
  /// **'Landslide risk notifications'**
  String get landslideRisk;

  /// No description provided for @weatherWarnings.
  ///
  /// In en, this message translates to:
  /// **'Weather Warnings'**
  String get weatherWarnings;

  /// No description provided for @severeWeatherUpdates.
  ///
  /// In en, this message translates to:
  /// **'Severe weather updates'**
  String get severeWeatherUpdates;

  /// No description provided for @connectedToTelegram.
  ///
  /// In en, this message translates to:
  /// **'Connected to @rescuenet_bot'**
  String get connectedToTelegram;

  /// No description provided for @receiveAlertsVia.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts via Telegram'**
  String get receiveAlertsVia;

  /// No description provided for @connectYourTelegramAccount.
  ///
  /// In en, this message translates to:
  /// **'Connect your Telegram account to receive instant alerts'**
  String get connectYourTelegramAccount;

  /// No description provided for @connectTelegram.
  ///
  /// In en, this message translates to:
  /// **'Connect Telegram'**
  String get connectTelegram;

  /// No description provided for @linkedToTelegram.
  ///
  /// In en, this message translates to:
  /// **'Connected to Telegram'**
  String get linkedToTelegram;

  /// No description provided for @disconnectTelegram.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Telegram'**
  String get disconnectTelegram;

  /// No description provided for @disconnectConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Telegram'**
  String get disconnectConfirmTitle;

  /// No description provided for @disconnectConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect your Telegram account? You will stop receiving Telegram alerts.'**
  String get disconnectConfirmMessage;

  /// No description provided for @telegramDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Telegram account disconnected'**
  String get telegramDisconnected;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear All Notifications'**
  String get clearAllNotifications;

  /// No description provided for @recentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Recent Notifications'**
  String get recentNotifications;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// No description provided for @testNotifications.
  ///
  /// In en, this message translates to:
  /// **'Test Notifications'**
  String get testNotifications;

  /// No description provided for @floodAlert.
  ///
  /// In en, this message translates to:
  /// **'Flood Alert'**
  String get floodAlert;

  /// No description provided for @thunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get thunderstorm;

  /// No description provided for @heavyRainfallWarning.
  ///
  /// In en, this message translates to:
  /// **'🌧️ Heavy Rainfall Warning'**
  String get heavyRainfallWarning;

  /// No description provided for @heavyRainfallExpected.
  ///
  /// In en, this message translates to:
  /// **'Heavy rainfall expected in {location}'**
  String heavyRainfallExpected(Object location);

  /// No description provided for @thunderstormAlert.
  ///
  /// In en, this message translates to:
  /// **'⛈️ Thunderstorm Alert'**
  String get thunderstormAlert;

  /// No description provided for @severeThunderstormWarning.
  ///
  /// In en, this message translates to:
  /// **'Severe thunderstorm warning for {location}'**
  String severeThunderstormWarning(Object location);

  /// No description provided for @alertTypes.
  ///
  /// In en, this message translates to:
  /// **'Alert Types'**
  String get alertTypes;

  /// No description provided for @telegramAlerts.
  ///
  /// In en, this message translates to:
  /// **'Telegram Alerts'**
  String get telegramAlerts;

  /// No description provided for @newNotifications.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String newNotifications(Object count);

  /// No description provided for @floodWarnings.
  ///
  /// In en, this message translates to:
  /// **'Flood Warnings'**
  String get floodWarnings;

  /// No description provided for @floodWarningsDesc.
  ///
  /// In en, this message translates to:
  /// **'Heavy rainfall and flooding alerts'**
  String get floodWarningsDesc;

  /// No description provided for @clearAllNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Notifications'**
  String get clearAllNotificationsTitle;

  /// No description provided for @clearAllNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all notifications? This action cannot be undone.'**
  String get clearAllNotificationsDesc;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @selectEmergencyType.
  ///
  /// In en, this message translates to:
  /// **'Select emergency type'**
  String get selectEmergencyType;

  /// No description provided for @emergencyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency Type'**
  String get emergencyTypeLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @enterLocationOrAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter location or address'**
  String get enterLocationOrAddress;

  /// No description provided for @useCurrentLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location on Map'**
  String get useCurrentLocationOnMap;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @autoFilledWithCurrentDate.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled with current date'**
  String get autoFilledWithCurrentDate;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @provideDetailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Provide detailed description of the emergency'**
  String get provideDetailedDescription;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload Images'**
  String get uploadImages;

  /// No description provided for @maximumImagesConstraint.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 images, up to 5MB each'**
  String get maximumImagesConstraint;

  /// No description provided for @clickToUploadOrDragDrop.
  ///
  /// In en, this message translates to:
  /// **'Click to upload or drag and drop'**
  String get clickToUploadOrDragDrop;

  /// No description provided for @pngJpgUpTo5MB.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG up to 5MB'**
  String get pngJpgUpTo5MB;

  /// No description provided for @chooseImages.
  ///
  /// In en, this message translates to:
  /// **'Choose Images ({current}/{max})'**
  String chooseImages(Object current, Object max);

  /// No description provided for @maxImagesReached.
  ///
  /// In en, this message translates to:
  /// **'Max Images Reached'**
  String get maxImagesReached;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @clearOrReset.
  ///
  /// In en, this message translates to:
  /// **'Clear / Reset'**
  String get clearOrReset;

  /// No description provided for @pleaseSelectEmergencyType.
  ///
  /// In en, this message translates to:
  /// **'Please select an emergency type'**
  String get pleaseSelectEmergencyType;

  /// No description provided for @pleaseEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location'**
  String get pleaseEnterLocation;

  /// No description provided for @pleaseProvideDescription.
  ///
  /// In en, this message translates to:
  /// **'Please provide a description'**
  String get pleaseProvideDescription;

  /// No description provided for @couldNotDetermineLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not determine location. Please use map picker.'**
  String get couldNotDetermineLocation;

  /// No description provided for @failedToCreateReport.
  ///
  /// In en, this message translates to:
  /// **'Failed to create report. Please try again.'**
  String get failedToCreateReport;

  /// No description provided for @errorSubmittingReport.
  ///
  /// In en, this message translates to:
  /// **'Error submitting report: {error}'**
  String errorSubmittingReport(Object error);

  /// No description provided for @uploadedReportButFailedImages.
  ///
  /// In en, this message translates to:
  /// **'Uploaded report but failed to upload images: {error}'**
  String uploadedReportButFailedImages(Object error);

  /// No description provided for @errorGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting location: {error}'**
  String errorGettingLocation(Object error);

  /// No description provided for @maximum3ImagesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 images allowed. Remove an image to add more.'**
  String get maximum3ImagesAllowed;

  /// No description provided for @noValidImagesSelected.
  ///
  /// In en, this message translates to:
  /// **'No valid images selected. Max 5MB per image.'**
  String get noValidImagesSelected;

  /// No description provided for @addedImages.
  ///
  /// In en, this message translates to:
  /// **'Added {count} image(s)'**
  String addedImages(Object count);

  /// No description provided for @addedImagesSkipped.
  ///
  /// In en, this message translates to:
  /// **'Added {count} image(s) ({skipped} skipped)'**
  String addedImagesSkipped(Object count, Object skipped);

  /// No description provided for @imageRemoved.
  ///
  /// In en, this message translates to:
  /// **'Image removed'**
  String get imageRemoved;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services disabled. Please enter location or use map picker.'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationServicesAreDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them.'**
  String get locationServicesAreDisabled;

  /// No description provided for @locationPermissionWasDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationPermissionWasDenied;

  /// No description provided for @locationPermissionsPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied. Open app settings to enable.'**
  String get locationPermissionsPermanentlyDenied;

  /// No description provided for @locationSelected.
  ///
  /// In en, this message translates to:
  /// **'Location selected: {address}'**
  String locationSelected(Object address);

  /// No description provided for @reportSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Report Submitted Successfully!'**
  String get reportSubmittedSuccessfully;

  /// No description provided for @yourEmergencyReportHasBeenReceived.
  ///
  /// In en, this message translates to:
  /// **'Your emergency report has been received. Reference: {reference}'**
  String yourEmergencyReportHasBeenReceived(Object reference);

  /// No description provided for @pleaseSignInBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Please sign in before submitting a report.'**
  String get pleaseSignInBeforeSubmitting;

  /// No description provided for @floodOption.
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get floodOption;

  /// No description provided for @fireOption.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fireOption;

  /// No description provided for @accidentOption.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get accidentOption;

  /// No description provided for @medicalEmergencyOption.
  ///
  /// In en, this message translates to:
  /// **'Medical Emergency'**
  String get medicalEmergencyOption;

  /// No description provided for @landslideOption.
  ///
  /// In en, this message translates to:
  /// **'Landslide'**
  String get landslideOption;

  /// No description provided for @otherOption.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherOption;

  /// No description provided for @reportStatus.
  ///
  /// In en, this message translates to:
  /// **'Report Status'**
  String get reportStatus;

  /// No description provided for @allReports.
  ///
  /// In en, this message translates to:
  /// **'All Reports'**
  String get allReports;

  /// No description provided for @searchByTypeOrLocation.
  ///
  /// In en, this message translates to:
  /// **'Search by type or location'**
  String get searchByTypeOrLocation;

  /// No description provided for @noReportsFound.
  ///
  /// In en, this message translates to:
  /// **'No reports found'**
  String get noReportsFound;

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Type'**
  String get filterByType;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Report Details'**
  String get reportDetails;

  /// No description provided for @reportId.
  ///
  /// In en, this message translates to:
  /// **'Report ID'**
  String get reportId;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @locationField.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationField;

  /// No description provided for @dateReported.
  ///
  /// In en, this message translates to:
  /// **'Date Reported'**
  String get dateReported;

  /// No description provided for @descriptionField.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionField;

  /// No description provided for @imageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageLabel;

  /// No description provided for @imagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get imagesLabel;

  /// No description provided for @statusTimeline.
  ///
  /// In en, this message translates to:
  /// **'Status Timeline'**
  String get statusTimeline;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report Submitted'**
  String get reportSubmitted;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @backToReports.
  ///
  /// In en, this message translates to:
  /// **'Back to Reports'**
  String get backToReports;

  /// No description provided for @unresolved.
  ///
  /// In en, this message translates to:
  /// **'Unresolved'**
  String get unresolved;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'By {reporter} • {date}'**
  String by(Object date, Object reporter);

  /// No description provided for @aidRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Aid Request Submitted!'**
  String get aidRequestSubmitted;

  /// No description provided for @yourRequestHasBeenReceived.
  ///
  /// In en, this message translates to:
  /// **'Your request has been received. Reference: {reference}'**
  String yourRequestHasBeenReceived(Object reference);

  /// No description provided for @aidTypeCategory.
  ///
  /// In en, this message translates to:
  /// **'Aid Type / Category'**
  String get aidTypeCategory;

  /// No description provided for @selectAidType.
  ///
  /// In en, this message translates to:
  /// **'Select aid type'**
  String get selectAidType;

  /// No description provided for @financialAid.
  ///
  /// In en, this message translates to:
  /// **'Financial Aid'**
  String get financialAid;

  /// No description provided for @disasterRelief.
  ///
  /// In en, this message translates to:
  /// **'Disaster Relief'**
  String get disasterRelief;

  /// No description provided for @medicalEmergencyFund.
  ///
  /// In en, this message translates to:
  /// **'Medical Emergency Fund'**
  String get medicalEmergencyFund;

  /// No description provided for @educationAid.
  ///
  /// In en, this message translates to:
  /// **'Education Aid'**
  String get educationAid;

  /// No description provided for @housingAssistance.
  ///
  /// In en, this message translates to:
  /// **'Housing Assistance'**
  String get housingAssistance;

  /// No description provided for @householdDetails.
  ///
  /// In en, this message translates to:
  /// **'Household Details'**
  String get householdDetails;

  /// No description provided for @monthlyHouseholdIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly Household Income (RM)'**
  String get monthlyHouseholdIncome;

  /// No description provided for @enterMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Enter monthly income'**
  String get enterMonthlyIncome;

  /// No description provided for @numberOfFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Number of Family Members'**
  String get numberOfFamilyMembers;

  /// No description provided for @enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter number'**
  String get enterNumber;

  /// No description provided for @familyMembersDetails.
  ///
  /// In en, this message translates to:
  /// **'Family Members Details'**
  String get familyMembersDetails;

  /// No description provided for @memberTitle.
  ///
  /// In en, this message translates to:
  /// **'Member {index}'**
  String memberTitle(Object index);

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameHint;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @employedFullTime.
  ///
  /// In en, this message translates to:
  /// **'Employed / Full-time'**
  String get employedFullTime;

  /// No description provided for @partTimeWorker.
  ///
  /// In en, this message translates to:
  /// **'Part-time Worker'**
  String get partTimeWorker;

  /// No description provided for @unemployed.
  ///
  /// In en, this message translates to:
  /// **'Unemployed'**
  String get unemployed;

  /// No description provided for @retired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get retired;

  /// No description provided for @childUnder12.
  ///
  /// In en, this message translates to:
  /// **'Child (Under 12)'**
  String get childUnder12;

  /// No description provided for @descriptionReason.
  ///
  /// In en, this message translates to:
  /// **'Description / Reason'**
  String get descriptionReason;

  /// No description provided for @explainWhyYouNeedAid.
  ///
  /// In en, this message translates to:
  /// **'Explain why you need this aid'**
  String get explainWhyYouNeedAid;

  /// No description provided for @submissionDate.
  ///
  /// In en, this message translates to:
  /// **'Submission Date'**
  String get submissionDate;

  /// No description provided for @autoFilledCurrentDate.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled with current date'**
  String get autoFilledCurrentDate;

  /// No description provided for @submitRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequestButton;

  /// No description provided for @clearResetButton.
  ///
  /// In en, this message translates to:
  /// **'Clear / Reset'**
  String get clearResetButton;

  /// No description provided for @addFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get addFamilyMember;

  /// No description provided for @selectAidTypeValidation.
  ///
  /// In en, this message translates to:
  /// **'Please select an aid type'**
  String get selectAidTypeValidation;

  /// No description provided for @enterIncomeValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter monthly household income'**
  String get enterIncomeValidation;

  /// No description provided for @familyMembersValidation.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one family member'**
  String get familyMembersValidation;

  /// No description provided for @descriptionValidation.
  ///
  /// In en, this message translates to:
  /// **'Please provide a description'**
  String get descriptionValidation;

  /// No description provided for @maximumFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Maximum of 20 family members allowed'**
  String get maximumFamilyMembers;

  /// No description provided for @failedToSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request'**
  String get failedToSubmitRequest;

  /// No description provided for @myAidRequests.
  ///
  /// In en, this message translates to:
  /// **'My Aid Requests'**
  String get myAidRequests;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @searchAidRequests.
  ///
  /// In en, this message translates to:
  /// **'Search aid requests'**
  String get searchAidRequests;

  /// No description provided for @allRequests.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allRequests;

  /// No description provided for @financialAidFilter.
  ///
  /// In en, this message translates to:
  /// **'Financial Aid'**
  String get financialAidFilter;

  /// No description provided for @disasterReliefFilter.
  ///
  /// In en, this message translates to:
  /// **'Disaster Relief'**
  String get disasterReliefFilter;

  /// No description provided for @educationAidFilter.
  ///
  /// In en, this message translates to:
  /// **'Education Aid'**
  String get educationAidFilter;

  /// No description provided for @medicalFundFilter.
  ///
  /// In en, this message translates to:
  /// **'Medical Fund'**
  String get medicalFundFilter;

  /// No description provided for @noAidRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No aid requests found'**
  String get noAidRequestsFound;

  /// No description provided for @requestDetails.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get requestDetails;

  /// No description provided for @requestIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get requestIdLabel;

  /// No description provided for @aidTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Aid Type'**
  String get aidTypeLabel;

  /// No description provided for @icNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'IC Number'**
  String get icNumberLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @dateSubmittedLabel.
  ///
  /// In en, this message translates to:
  /// **'Date Submitted'**
  String get dateSubmittedLabel;

  /// No description provided for @monthlyIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Income'**
  String get monthlyIncomeLabel;

  /// No description provided for @familyMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembersLabel;

  /// No description provided for @familyComposition.
  ///
  /// In en, this message translates to:
  /// **'Family Composition'**
  String get familyComposition;

  /// No description provided for @backToList.
  ///
  /// In en, this message translates to:
  /// **'Back to List'**
  String get backToList;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorPrefix;

  /// No description provided for @pendingTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String pendingTabLabel(Object count);

  /// No description provided for @approvedTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved ({count})'**
  String approvedTabLabel(Object count);

  /// No description provided for @rejectedTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejected ({count})'**
  String rejectedTabLabel(Object count);

  /// No description provided for @housingAssistanceFilter.
  ///
  /// In en, this message translates to:
  /// **'Housing Assistance'**
  String get housingAssistanceFilter;

  /// No description provided for @otherCategoryFilter.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategoryFilter;

  /// No description provided for @medicalEmergencyFundFilter.
  ///
  /// In en, this message translates to:
  /// **'Medical Emergency Fund'**
  String get medicalEmergencyFundFilter;

  /// No description provided for @availableAidPrograms.
  ///
  /// In en, this message translates to:
  /// **'Available Aid Programs'**
  String get availableAidPrograms;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get filterByCategory;

  /// No description provided for @allPrograms.
  ///
  /// In en, this message translates to:
  /// **'All Programs'**
  String get allPrograms;

  /// No description provided for @financialAidCategory.
  ///
  /// In en, this message translates to:
  /// **'Financial Aid'**
  String get financialAidCategory;

  /// No description provided for @disasterReliefCategory.
  ///
  /// In en, this message translates to:
  /// **'Disaster Relief'**
  String get disasterReliefCategory;

  /// No description provided for @medicalCategory.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get medicalCategory;

  /// No description provided for @educationCategory.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get educationCategory;

  /// No description provided for @housingCategory.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get housingCategory;

  /// No description provided for @noProgramsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No programs available'**
  String get noProgramsAvailable;

  /// No description provided for @noProgramsMatch.
  ///
  /// In en, this message translates to:
  /// **'No aid programs match the selected category'**
  String get noProgramsMatch;

  /// No description provided for @failedToLoadPrograms.
  ///
  /// In en, this message translates to:
  /// **'Failed to load programs'**
  String get failedToLoadPrograms;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @programDetails.
  ///
  /// In en, this message translates to:
  /// **'Program Details'**
  String get programDetails;

  /// No description provided for @programIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Program ID'**
  String get programIdLabel;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateLabel;

  /// No description provided for @endDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDateLabel;

  /// No description provided for @eligibilityCriteriaLabel.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Criteria'**
  String get eligibilityCriteriaLabel;

  /// No description provided for @aidAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Aid Amount'**
  String get aidAmountLabel;

  /// No description provided for @howToApply.
  ///
  /// In en, this message translates to:
  /// **'How to Apply'**
  String get howToApply;

  /// No description provided for @applyStep1.
  ///
  /// In en, this message translates to:
  /// **'Go to \"Request Aid\" section'**
  String get applyStep1;

  /// No description provided for @applyStep2.
  ///
  /// In en, this message translates to:
  /// **'Select the appropriate aid category'**
  String get applyStep2;

  /// No description provided for @applyStep3.
  ///
  /// In en, this message translates to:
  /// **'Fill in your household details'**
  String get applyStep3;

  /// No description provided for @applyStep4.
  ///
  /// In en, this message translates to:
  /// **'Submit the request form'**
  String get applyStep4;

  /// No description provided for @applyStep5.
  ///
  /// In en, this message translates to:
  /// **'Wait for approval notification'**
  String get applyStep5;

  /// No description provided for @importantNote.
  ///
  /// In en, this message translates to:
  /// **'Important Note'**
  String get importantNote;

  /// No description provided for @applicationNoteText.
  ///
  /// In en, this message translates to:
  /// **'Applications will be reviewed within 7-14 working days. You will be notified via email and in-app notification.'**
  String get applicationNoteText;

  /// No description provided for @applyForThisProgram.
  ///
  /// In en, this message translates to:
  /// **'Apply for This Program'**
  String get applyForThisProgram;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notApplicable;

  /// No description provided for @locationServices.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them.'**
  String get locationServices;

  /// No description provided for @locationPermissionPermanent.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied. Open app settings to enable.'**
  String get locationPermissionPermanent;

  /// No description provided for @locatingYou.
  ///
  /// In en, this message translates to:
  /// **'Locating you...'**
  String get locatingYou;

  /// No description provided for @centeredOnYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Centered on your location'**
  String get centeredOnYourLocation;

  /// No description provided for @errorLocating.
  ///
  /// In en, this message translates to:
  /// **'Error locating: {error}'**
  String errorLocating(Object error);

  /// No description provided for @severityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severityLabel;

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceLabel;

  /// No description provided for @timeAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'Time ago'**
  String get timeAgoLabel;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOut;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @yourCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Current Location'**
  String get yourCurrentLocation;

  /// No description provided for @tapToLocateOnMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to locate on map'**
  String get tapToLocateOnMap;

  /// No description provided for @activeWarningsNearby.
  ///
  /// In en, this message translates to:
  /// **'Active Warnings Nearby'**
  String get activeWarningsNearby;

  /// No description provided for @noWarningsInYourArea.
  ///
  /// In en, this message translates to:
  /// **'No warnings in your area'**
  String get noWarningsInYourArea;

  /// No description provided for @warningLevels.
  ///
  /// In en, this message translates to:
  /// **'Warning Levels'**
  String get warningLevels;

  /// No description provided for @highImmediateDanger.
  ///
  /// In en, this message translates to:
  /// **'High - Immediate danger'**
  String get highImmediateDanger;

  /// No description provided for @mediumExerciseCaution.
  ///
  /// In en, this message translates to:
  /// **'Medium - Exercise caution'**
  String get mediumExerciseCaution;

  /// No description provided for @lowBeAware.
  ///
  /// In en, this message translates to:
  /// **'Low - Be aware'**
  String get lowBeAware;

  /// No description provided for @refreshMap.
  ///
  /// In en, this message translates to:
  /// **'Refresh Map'**
  String get refreshMap;

  /// No description provided for @youMarker.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youMarker;

  /// No description provided for @noWarningsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No warnings available for your area'**
  String get noWarningsAvailable;

  /// No description provided for @warningDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning Details'**
  String get warningDetailsTitle;

  /// No description provided for @highSeverity.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get highSeverity;

  /// No description provided for @mediumSeverity.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get mediumSeverity;

  /// No description provided for @lowSeverity.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get lowSeverity;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @aiGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am the RescueNet AI Assistant. I can help you with emergency procedures, disaster preparedness, aid information, and answer questions about the rescue network. How can I assist you today?'**
  String get aiGreeting;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @quickQuestions.
  ///
  /// In en, this message translates to:
  /// **'Quick questions:'**
  String get quickQuestions;

  /// No description provided for @whatShouldIDoDuringFlood.
  ///
  /// In en, this message translates to:
  /// **'What should I do during a flood?'**
  String get whatShouldIDoDuringFlood;

  /// No description provided for @howDoICheckReportStatus.
  ///
  /// In en, this message translates to:
  /// **'How do I check my report status?'**
  String get howDoICheckReportStatus;

  /// No description provided for @whatAidProgramsAvailable.
  ///
  /// In en, this message translates to:
  /// **'What aid programs are available?'**
  String get whatAidProgramsAvailable;

  /// No description provided for @emergencyContactNumbers.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact numbers'**
  String get emergencyContactNumbers;

  /// No description provided for @troubleGeneratingResponse.
  ///
  /// In en, this message translates to:
  /// **'I\'m having trouble generating a response. Please try again.'**
  String get troubleGeneratingResponse;

  /// No description provided for @errorParsingResponse.
  ///
  /// In en, this message translates to:
  /// **'Error parsing response:'**
  String get errorParsingResponse;

  /// No description provided for @errorConnectingAPI.
  ///
  /// In en, this message translates to:
  /// **'Error connecting to Hugging Face API:'**
  String get errorConnectingAPI;

  /// No description provided for @apiTokenNotSet.
  ///
  /// In en, this message translates to:
  /// **'Error: Hugging Face API token not set. Please update lib/config/hugging_face_config.dart with your token from https://huggingface.co/settings/tokens'**
  String get apiTokenNotSet;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ms': return AppLocalizationsMs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
