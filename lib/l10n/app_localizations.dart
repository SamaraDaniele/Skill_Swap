import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Skill Swap'**
  String get appTitle;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Teach what you know. Learn what you love.'**
  String get authTagline;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInAction;

  /// No description provided for @signUpAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpAction;

  /// Text before the create-account link on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHerePrompt;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccountPrompt;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot my password'**
  String get forgotPassword;

  /// Divider label between email sign-in and social sign-in.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orSeparator;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @socialSignInSoon.
  ///
  /// In en, this message translates to:
  /// **'This sign-in option is coming soon. For now, use email and password.'**
  String get socialSignInSoon;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a link to choose a new password.'**
  String get resetPasswordBody;

  /// Shown after a reset request. Must not reveal whether the account exists.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that email, the link is on its way.'**
  String get resetPasswordSent;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validationEmail;

  /// No description provided for @validationPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get validationPassword;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get validationRequired;

  /// No description provided for @validationPickSkill.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one skill'**
  String get validationPickSkill;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get errorEmailInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password.'**
  String get errorWeakPassword;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get errorTooManyRequests;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission for this action.'**
  String get errorPermission;

  /// No description provided for @errorInvalidImage.
  ///
  /// In en, this message translates to:
  /// **'This image can\'t be used. Try another photo.'**
  String get errorInvalidImage;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryAction;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell people what you can teach and what you want to learn.'**
  String get profileSetupSubtitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get bioLabel;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'A short intro, availability, preferred format…'**
  String get bioHint;

  /// No description provided for @photoAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get photoAddAction;

  /// No description provided for @photoChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get photoChangeAction;

  /// No description provided for @photoRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoRemoveAction;

  /// No description provided for @photoProcessing.
  ///
  /// In en, this message translates to:
  /// **'Preparing photo…'**
  String get photoProcessing;

  /// No description provided for @photoHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. A square crop of your photo; location data is removed.'**
  String get photoHint;

  /// No description provided for @teachSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'I can teach'**
  String get teachSectionTitle;

  /// No description provided for @learnSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'I want to learn'**
  String get learnSectionTitle;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get navDiscover;

  /// No description provided for @navMatches.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navMatches;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @discoverEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No one new for now'**
  String get discoverEmptyTitle;

  /// No description provided for @discoverEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add more skills to your profile or come back later.'**
  String get discoverEmptyBody;

  /// No description provided for @refreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshAction;

  /// No description provided for @likeAction.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get likeAction;

  /// No description provided for @passAction.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get passAction;

  /// No description provided for @teachesLabel.
  ///
  /// In en, this message translates to:
  /// **'Teaches'**
  String get teachesLabel;

  /// No description provided for @wantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Wants to learn'**
  String get wantsLabel;

  /// No description provided for @compatibility.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String compatibility(int percent);

  /// No description provided for @matchDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'It\'s a match!'**
  String get matchDialogTitle;

  /// No description provided for @matchDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You and {name} can start chatting now.'**
  String matchDialogBody(String name);

  /// No description provided for @openChatAction.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get openChatAction;

  /// No description provided for @keepExploringAction.
  ///
  /// In en, this message translates to:
  /// **'Keep exploring'**
  String get keepExploringAction;

  /// No description provided for @matchesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get matchesEmptyTitle;

  /// No description provided for @matchesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Show interest in profiles on Discover. When it\'s mutual, they show up here.'**
  String get matchesEmptyBody;

  /// No description provided for @matchesNoMessages.
  ///
  /// In en, this message translates to:
  /// **'Say hi to start the exchange'**
  String get matchesNoMessages;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatHint;

  /// No description provided for @sendAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendAction;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Agree on topics, format and a time that works for both of you.'**
  String get chatEmpty;

  /// No description provided for @signOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutAction;

  /// No description provided for @editProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileAction;

  /// No description provided for @skillExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get skillExcel;

  /// No description provided for @skillEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get skillEnglish;

  /// No description provided for @skillSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get skillSpanish;

  /// No description provided for @skillProgramming.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get skillProgramming;

  /// No description provided for @skillPython.
  ///
  /// In en, this message translates to:
  /// **'Python'**
  String get skillPython;

  /// No description provided for @skillGuitar.
  ///
  /// In en, this message translates to:
  /// **'Guitar'**
  String get skillGuitar;

  /// No description provided for @skillPiano.
  ///
  /// In en, this message translates to:
  /// **'Piano'**
  String get skillPiano;

  /// No description provided for @skillMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get skillMath;

  /// No description provided for @skillPhysics.
  ///
  /// In en, this message translates to:
  /// **'Physics'**
  String get skillPhysics;

  /// No description provided for @skillChemistry.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get skillChemistry;

  /// No description provided for @skillPhotoEditing.
  ///
  /// In en, this message translates to:
  /// **'Photo editing'**
  String get skillPhotoEditing;

  /// No description provided for @skillVideoEditing.
  ///
  /// In en, this message translates to:
  /// **'Video editing'**
  String get skillVideoEditing;

  /// No description provided for @skillCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get skillCooking;

  /// No description provided for @skillCrafts.
  ///
  /// In en, this message translates to:
  /// **'Crafts'**
  String get skillCrafts;

  /// No description provided for @skillDrawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get skillDrawing;

  /// No description provided for @skillWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get skillWriting;

  /// No description provided for @skillPublicSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Public speaking'**
  String get skillPublicSpeaking;

  /// No description provided for @skillPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get skillPhotography;

  /// No description provided for @skillDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get skillDesign;

  /// No description provided for @skillMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get skillMarketing;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @unmatchAction.
  ///
  /// In en, this message translates to:
  /// **'Undo match'**
  String get unmatchAction;

  /// No description provided for @unmatchConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo this match?'**
  String get unmatchConfirmTitle;

  /// No description provided for @unmatchConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The conversation will be closed for both of you. This can\'t be undone.'**
  String get unmatchConfirmBody;

  /// No description provided for @matchClosedDone.
  ///
  /// In en, this message translates to:
  /// **'Match undone'**
  String get matchClosedDone;

  /// No description provided for @blockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockAction;

  /// No description provided for @blockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockConfirmTitle(String name);

  /// No description provided for @blockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t match again and no more messages can be sent. This can\'t be undone.'**
  String get blockConfirmBody;

  /// No description provided for @blockDone.
  ///
  /// In en, this message translates to:
  /// **'Profile blocked'**
  String get blockDone;

  /// No description provided for @reportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportAction;

  /// No description provided for @reportProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report profile'**
  String get reportProfileTooltip;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String reportTitle(String name);

  /// No description provided for @reportIntro.
  ///
  /// In en, this message translates to:
  /// **'Your report is confidential. The profile will also be blocked for you.'**
  String get reportIntro;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or threats'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonFake.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get reportReasonFake;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// No description provided for @reportDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDetailsLabel;

  /// No description provided for @reportPickReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason'**
  String get reportPickReason;

  /// No description provided for @reportSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Report and block'**
  String get reportSubmitAction;

  /// No description provided for @reportDone.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thanks for helping keep the community safe.'**
  String get reportDone;

  /// No description provided for @chatClosedNotice.
  ///
  /// In en, this message translates to:
  /// **'This conversation has ended.'**
  String get chatClosedNotice;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you continue'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'Skill Swap connects people who want to exchange knowledge. To keep everyone safe, all members must be adults and follow the community rules.'**
  String get consentBody;

  /// No description provided for @consentCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I am 18 or older and accept the Terms and Community rules'**
  String get consentCheckbox;

  /// No description provided for @consentRequired.
  ///
  /// In en, this message translates to:
  /// **'Accept to continue'**
  String get consentRequired;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @readTermsAction.
  ///
  /// In en, this message translates to:
  /// **'Read the terms'**
  String get readTermsAction;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and community rules'**
  String get termsTitle;

  /// No description provided for @termsBody.
  ///
  /// In en, this message translates to:
  /// **'• You must be 18 or older.\n• Treat everyone with respect: harassment, threats, hate speech and sexual content are not allowed.\n• Use your real name and describe your skills honestly.\n• No spam, scams or hidden charges.\n• Don\'t share other people\'s personal data.\n• Prefer public places or video calls for your sessions.\n\nYou can undo a match, block or report anyone from the chat menu or the profile card. Reports are confidential and reviewed by the project team; breaking these rules can lead to account removal.\n\nThis is a summary written for an academic project and is not a legally reviewed agreement.'**
  String get termsBody;

  /// No description provided for @matchTitle.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get matchTitle;

  /// No description provided for @notificationsSoon.
  ///
  /// In en, this message translates to:
  /// **'Notifications (coming soon)'**
  String get notificationsSoon;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get openProfile;

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo last skip'**
  String get undoAction;

  /// No description provided for @saveForLaterSoon.
  ///
  /// In en, this message translates to:
  /// **'Save for later (coming soon)'**
  String get saveForLaterSoon;

  /// No description provided for @knowledgeMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Knowledge match'**
  String get knowledgeMatchTitle;

  /// No description provided for @knowledgeExchange.
  ///
  /// In en, this message translates to:
  /// **'You teach {teach} and learn {learn} with {name}.'**
  String knowledgeExchange(String teach, String learn, String name);

  /// No description provided for @knowledgeTeach.
  ///
  /// In en, this message translates to:
  /// **'You know {skill} and {name} wants to learn it!'**
  String knowledgeTeach(String skill, String name);

  /// No description provided for @knowledgeLearn.
  ///
  /// In en, this message translates to:
  /// **'{name} knows {skill}, which you want to learn!'**
  String knowledgeLearn(String name, String skill);

  /// No description provided for @skillPair.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String skillPair(String first, String second);

  /// No description provided for @profileCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile of {name}'**
  String profileCardLabel(String name);

  /// No description provided for @navMySkills.
  ///
  /// In en, this message translates to:
  /// **'My Skills'**
  String get navMySkills;

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalLabel;

  /// No description provided for @goalLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn {skill}'**
  String goalLearn(String skill);

  /// No description provided for @compatibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Affinity'**
  String get compatibilityLabel;

  /// No description provided for @profileDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'View profile details'**
  String get profileDetailsAction;

  /// No description provided for @newMatchesBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match with no messages yet} other{{count} matches with no messages yet}}'**
  String newMatchesBadge(int count);

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @communitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share, learn and inspire.'**
  String get communitySubtitle;

  /// No description provided for @searchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchAction;

  /// No description provided for @newPostAction.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get newPostAction;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @unreadBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread} other{{count} unread}}'**
  String unreadBadge(int count);

  /// No description provided for @feedForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get feedForYou;

  /// No description provided for @feedFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedFollowing;

  /// No description provided for @feedSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get feedSkills;

  /// No description provided for @feedProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get feedProjects;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share a project, a tip or a question.'**
  String get feedEmptyBody;

  /// No description provided for @feedFollowingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing from people you follow'**
  String get feedFollowingEmptyTitle;

  /// No description provided for @feedFollowingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Follow members to see their posts here.'**
  String get feedFollowingEmptyBody;

  /// No description provided for @feedSkillsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts about your skills'**
  String get feedSkillsEmptyTitle;

  /// No description provided for @feedSkillsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Posts about the skills you teach or want to learn appear here.'**
  String get feedSkillsEmptyBody;

  /// No description provided for @feedProjectsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get feedProjectsEmptyTitle;

  /// No description provided for @feedProjectsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Show what you built: post a project.'**
  String get feedProjectsEmptyBody;

  /// No description provided for @searchPeopleAction.
  ///
  /// In en, this message translates to:
  /// **'Find people'**
  String get searchPeopleAction;

  /// No description provided for @feedEnd.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get feedEnd;

  /// No description provided for @loadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more. Tap to try again'**
  String get loadMoreFailed;

  /// No description provided for @loadMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMoreAction;

  /// No description provided for @loadingPosts.
  ///
  /// In en, this message translates to:
  /// **'Loading posts'**
  String get loadingPosts;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @timeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String timeMinutes(int n);

  /// No description provided for @timeHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String timeHours(int n);

  /// No description provided for @timeDays.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String timeDays(int n);

  /// No description provided for @postTypeProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get postTypeProject;

  /// No description provided for @postTypeTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get postTypeTip;

  /// No description provided for @postTypeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get postTypeQuestion;

  /// No description provided for @postTypeAchievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get postTypeAchievement;

  /// No description provided for @postTypeWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get postTypeWork;

  /// No description provided for @hashtagSemantics.
  ///
  /// In en, this message translates to:
  /// **'Hashtag {tag}'**
  String hashtagSemantics(String tag);

  /// No description provided for @memberFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberFallbackName;

  /// No description provided for @teachesSkill.
  ///
  /// In en, this message translates to:
  /// **'Teaches {skill}'**
  String teachesSkill(String skill);

  /// No description provided for @openMemberProfile.
  ///
  /// In en, this message translates to:
  /// **'Open {name}\'s profile'**
  String openMemberProfile(String name);

  /// No description provided for @postEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get postEdited;

  /// No description provided for @postMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Post options'**
  String get postMenuTooltip;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @postImageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Image {index} of {total}'**
  String postImageSemantics(int index, int total);

  /// No description provided for @imageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get imageLoadFailed;

  /// No description provided for @learnPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Skill available to teach'**
  String get learnPanelTitle;

  /// No description provided for @learnPanelBody.
  ///
  /// In en, this message translates to:
  /// **'{name} can teach {skills}.'**
  String learnPanelBody(String name, String skills);

  /// No description provided for @learnWithAction.
  ///
  /// In en, this message translates to:
  /// **'I want to learn with {name}'**
  String learnWithAction(String name);

  /// No description provided for @learnPending.
  ///
  /// In en, this message translates to:
  /// **'Interest sent · waiting for an answer'**
  String get learnPending;

  /// No description provided for @learnConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn with {name}?'**
  String learnConfirmTitle(String name);

  /// No description provided for @learnConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This sends your interest through Match, like a swipe right. {name} will be notified that you want to learn from this post. If {name} is also interested in you, you match and the chat opens.'**
  String learnConfirmBody(String name);

  /// No description provided for @learnConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Send interest'**
  String get learnConfirmAction;

  /// No description provided for @learnSent.
  ///
  /// In en, this message translates to:
  /// **'Interest sent to {name}. You will match if the interest is mutual.'**
  String learnSent(String name);

  /// No description provided for @commentAction.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentAction;

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no comments} =1{1 comment} other{{count} comments}}'**
  String commentsCount(int count);

  /// No description provided for @likesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no likes} =1{1 like} other{{count} likes}}'**
  String likesCount(int count);

  /// No description provided for @likePostAction.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likePostAction;

  /// No description provided for @unlikeAction.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get unlikeAction;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @unsaveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get unsaveAction;

  /// No description provided for @postSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get postSaved;

  /// No description provided for @postUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get postUnsaved;

  /// No description provided for @editPostAction.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get editPostAction;

  /// No description provided for @deletePostAction.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get deletePostAction;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get deletePostTitle;

  /// No description provided for @deletePostBody.
  ///
  /// In en, this message translates to:
  /// **'The post and its images are removed for everyone. This cannot be undone.'**
  String get deletePostBody;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @copyLinkAction.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLinkAction;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @reportPostAction.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get reportPostAction;

  /// No description provided for @reportCommentAction.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get reportCommentAction;

  /// No description provided for @reportMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Report member'**
  String get reportMemberAction;

  /// No description provided for @blockMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String blockMemberAction(String name);

  /// No description provided for @communityBlockBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see {name}\'s posts or comments, they can\'t interact with your content, and you won\'t match. This cannot be undone.'**
  String communityBlockBody(String name);

  /// No description provided for @reportPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get reportPostTitle;

  /// No description provided for @reportCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get reportCommentTitle;

  /// No description provided for @contentReportIntro.
  ///
  /// In en, this message translates to:
  /// **'Your report is confidential and will be reviewed by the moderators.'**
  String get contentReportIntro;

  /// No description provided for @contentReportDone.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thank you for keeping the community safe.'**
  String get contentReportDone;

  /// No description provided for @reportReasonOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive content'**
  String get reportReasonOffensive;

  /// No description provided for @reportReasonScam.
  ///
  /// In en, this message translates to:
  /// **'Scam'**
  String get reportReasonScam;

  /// No description provided for @sendInChat.
  ///
  /// In en, this message translates to:
  /// **'Send in a chat'**
  String get sendInChat;

  /// No description provided for @shareNoChats.
  ///
  /// In en, this message translates to:
  /// **'You have no open chats yet. Copy the link instead.'**
  String get shareNoChats;

  /// No description provided for @sharePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to {name}?'**
  String sharePostTitle(String name);

  /// No description provided for @sharePostBody.
  ///
  /// In en, this message translates to:
  /// **'A message with the link to this post will be sent in your chat.'**
  String get sharePostBody;

  /// No description provided for @sharedPostMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out this post on Skill Swap: {link}'**
  String sharedPostMessage(String link);

  /// No description provided for @postSharedTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {name}'**
  String postSharedTo(String name);

  /// No description provided for @openSharedPost.
  ///
  /// In en, this message translates to:
  /// **'Open post'**
  String get openSharedPost;

  /// No description provided for @postTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postTitle;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @commentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Start the conversation!'**
  String get commentsEmpty;

  /// No description provided for @loadMoreComments.
  ///
  /// In en, this message translates to:
  /// **'Load more comments'**
  String get loadMoreComments;

  /// No description provided for @showReplies.
  ///
  /// In en, this message translates to:
  /// **'Show replies'**
  String get showReplies;

  /// No description provided for @hideReplies.
  ///
  /// In en, this message translates to:
  /// **'Hide replies'**
  String get hideReplies;

  /// No description provided for @replyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyAction;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(String name);

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get commentHint;

  /// No description provided for @commentMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Comment options'**
  String get commentMenuTooltip;

  /// No description provided for @commentTooFast.
  ///
  /// In en, this message translates to:
  /// **'Wait a moment before commenting again.'**
  String get commentTooFast;

  /// No description provided for @deleteCommentAction.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get deleteCommentAction;

  /// No description provided for @commentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted'**
  String get commentDeleted;

  /// No description provided for @postNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Post unavailable'**
  String get postNotFoundTitle;

  /// No description provided for @postNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted, or the link is wrong.'**
  String get postNotFoundBody;

  /// No description provided for @backToCommunity.
  ///
  /// In en, this message translates to:
  /// **'Back to Community'**
  String get backToCommunity;

  /// No description provided for @newPostTitle.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get newPostTitle;

  /// No description provided for @editPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get editPostTitle;

  /// No description provided for @previewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewAction;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTitle;

  /// No description provided for @addImagesAction.
  ///
  /// In en, this message translates to:
  /// **'Add images'**
  String get addImagesAction;

  /// No description provided for @removeImageAction.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImageAction;

  /// No description provided for @imagesHint.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} images. We resize them and remove location data.'**
  String imagesHint(int max);

  /// No description provided for @imagePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your photos.'**
  String get imagePickFailed;

  /// No description provided for @imagesSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 image could not be used} other{{count} images could not be used}}'**
  String imagesSkipped(int count);

  /// No description provided for @editImagesLocked.
  ///
  /// In en, this message translates to:
  /// **'Images cannot be changed after publishing. To change them, delete the post and publish again.'**
  String get editImagesLocked;

  /// No description provided for @postDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get postDescriptionLabel;

  /// No description provided for @postDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your project, tip or question…'**
  String get postDescriptionHint;

  /// No description provided for @postTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get postTypeLabel;

  /// No description provided for @postSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Related skills ({count}/{max})'**
  String postSkillsLabel(int count, int max);

  /// No description provided for @postSkillsHint.
  ///
  /// In en, this message translates to:
  /// **'From your profile. Skills you teach show the \"learn with you\" button.'**
  String get postSkillsHint;

  /// No description provided for @postSkillsMax.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {max} skills.'**
  String postSkillsMax(int max);

  /// No description provided for @postTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Hashtags'**
  String get postTagsLabel;

  /// No description provided for @postTagsHint.
  ///
  /// In en, this message translates to:
  /// **'#design #ui'**
  String get postTagsHint;

  /// No description provided for @postTagsHelper.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} valid tags (letters, numbers, _)'**
  String postTagsHelper(int count, int max);

  /// No description provided for @visibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Who can see it?'**
  String get visibilityLabel;

  /// No description provided for @visibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get visibilityPublic;

  /// No description provided for @visibilityPublicBody.
  ///
  /// In en, this message translates to:
  /// **'All Skill Swap members.'**
  String get visibilityPublicBody;

  /// No description provided for @publishAction.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishAction;

  /// No description provided for @saveChangesAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesAction;

  /// No description provided for @preparingImages.
  ///
  /// In en, this message translates to:
  /// **'Preparing images {done}/{total}…'**
  String preparingImages(int done, int total);

  /// No description provided for @sendingPost.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sendingPost;

  /// No description provided for @postEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Write something or add an image.'**
  String get postEmptyError;

  /// No description provided for @postTooLongError.
  ///
  /// In en, this message translates to:
  /// **'The description is too long.'**
  String get postTooLongError;

  /// No description provided for @postTooFast.
  ///
  /// In en, this message translates to:
  /// **'Wait {seconds} s before publishing again.'**
  String postTooFast(int seconds);

  /// No description provided for @postPublished.
  ///
  /// In en, this message translates to:
  /// **'Post published'**
  String get postPublished;

  /// No description provided for @postUpdated.
  ///
  /// In en, this message translates to:
  /// **'Post updated'**
  String get postUpdated;

  /// No description provided for @discardPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard post?'**
  String get discardPostTitle;

  /// No description provided for @discardPostBody.
  ///
  /// In en, this message translates to:
  /// **'What you wrote will be lost.'**
  String get discardPostBody;

  /// No description provided for @keepEditingAction.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditingAction;

  /// No description provided for @discardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardAction;

  /// No description provided for @errorInvalidPost.
  ///
  /// In en, this message translates to:
  /// **'Check the post: it is empty or too long.'**
  String get errorInvalidPost;

  /// No description provided for @memberMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get memberMenuTooltip;

  /// No description provided for @memberBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'You blocked {name}'**
  String memberBlockedTitle(String name);

  /// No description provided for @memberBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Their content is hidden for you.'**
  String get memberBlockedBody;

  /// No description provided for @memberNotFound.
  ///
  /// In en, this message translates to:
  /// **'Member not found'**
  String get memberNotFound;

  /// No description provided for @portfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Posts and portfolio'**
  String get portfolioTitle;

  /// No description provided for @portfolioEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get portfolioEmpty;

  /// No description provided for @portfolioEmptyMine.
  ///
  /// In en, this message translates to:
  /// **'Your posts appear here. Share your first project!'**
  String get portfolioEmptyMine;

  /// No description provided for @statPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get statPosts;

  /// No description provided for @statFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get statFollowers;

  /// No description provided for @statFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get statFollowing;

  /// No description provided for @followAction.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followAction;

  /// No description provided for @followingAction.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingAction;

  /// No description provided for @messageAction.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageAction;

  /// No description provided for @openPostSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open post: {text}'**
  String openPostSemantics(String text);

  /// No description provided for @followersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No followers yet'**
  String get followersEmpty;

  /// No description provided for @followingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not following anyone yet'**
  String get followingEmpty;

  /// No description provided for @myPortfolioAction.
  ///
  /// In en, this message translates to:
  /// **'My posts'**
  String get myPortfolioAction;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @savedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get savedEmptyTitle;

  /// No description provided for @savedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on a post to keep it here. Only you see this list.'**
  String get savedEmptyBody;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search people, posts or #tags'**
  String get searchHint;

  /// No description provided for @searchPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get searchPeople;

  /// No description provided for @searchPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get searchPosts;

  /// No description provided for @searchSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get searchSkills;

  /// No description provided for @searchPeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 letters of a name.'**
  String get searchPeopleHint;

  /// No description provided for @searchNoPeople.
  ///
  /// In en, this message translates to:
  /// **'No one found for \"{term}\"'**
  String searchNoPeople(String term);

  /// No description provided for @searchPeopleLimit.
  ///
  /// In en, this message translates to:
  /// **'The search matches the beginning of the name.'**
  String get searchPeopleLimit;

  /// No description provided for @searchPostsHint.
  ///
  /// In en, this message translates to:
  /// **'Search a word or a #tag.'**
  String get searchPostsHint;

  /// No description provided for @searchNoPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts with \"{term}\"'**
  String searchNoPosts(String term);

  /// No description provided for @searchPostsLimit.
  ///
  /// In en, this message translates to:
  /// **'The search uses one word or tag at a time.'**
  String get searchPostsLimit;

  /// No description provided for @searchSkillsHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a skill to see who teaches it and related posts.'**
  String get searchSkillsHint;

  /// No description provided for @skillTeachersTitle.
  ///
  /// In en, this message translates to:
  /// **'Who teaches {skill}'**
  String skillTeachersTitle(String skill);

  /// No description provided for @skillTeachersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one teaches this skill yet.'**
  String get skillTeachersEmpty;

  /// No description provided for @skillPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Posts about {skill}'**
  String skillPostsTitle(String skill);

  /// No description provided for @skillPostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts about this skill yet.'**
  String get skillPostsEmpty;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Likes, comments, follows and learning requests appear here.'**
  String get notificationsEmptyBody;

  /// No description provided for @markAllReadAction.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllReadAction;

  /// No description provided for @unreadLabel.
  ///
  /// In en, this message translates to:
  /// **'unread'**
  String get unreadLabel;

  /// No description provided for @notificationLike.
  ///
  /// In en, this message translates to:
  /// **'{name} liked your post'**
  String notificationLike(String name);

  /// No description provided for @notificationComment.
  ///
  /// In en, this message translates to:
  /// **'{name} commented on your post'**
  String notificationComment(String name);

  /// No description provided for @notificationReply.
  ///
  /// In en, this message translates to:
  /// **'{name} replied to your comment'**
  String notificationReply(String name);

  /// No description provided for @notificationFollow.
  ///
  /// In en, this message translates to:
  /// **'{name} started following you'**
  String notificationFollow(String name);

  /// No description provided for @notificationLearn.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to learn with you'**
  String notificationLearn(String name);

  /// No description provided for @contentReportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get contentReportSubmit;

  /// No description provided for @deleteNotificationAction.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get deleteNotificationAction;

  /// No description provided for @postTypeKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get postTypeKnowledge;

  /// No description provided for @errorInvalidVideo.
  ///
  /// In en, this message translates to:
  /// **'Use an MP4 video of up to 60 seconds and 2.3 MB.'**
  String get errorInvalidVideo;

  /// No description provided for @addVideoAction.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get addVideoAction;

  /// No description provided for @removeVideoAction.
  ///
  /// In en, this message translates to:
  /// **'Remove video'**
  String get removeVideoAction;

  /// No description provided for @videoHint.
  ///
  /// In en, this message translates to:
  /// **'Or 1 video of up to 60 s (MP4, up to 2.3 MB).'**
  String get videoHint;

  /// No description provided for @videoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open your videos.'**
  String get videoPickFailed;

  /// No description provided for @preparingVideo.
  ///
  /// In en, this message translates to:
  /// **'Preparing the video…'**
  String get preparingVideo;

  /// No description provided for @playVideoAction.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get playVideoAction;

  /// No description provided for @pauseVideoAction.
  ///
  /// In en, this message translates to:
  /// **'Pause video'**
  String get pauseVideoAction;

  /// No description provided for @replayVideoAction.
  ///
  /// In en, this message translates to:
  /// **'Watch again'**
  String get replayVideoAction;

  /// No description provided for @fullscreenAction.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullscreenAction;

  /// No description provided for @exitFullscreenAction.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get exitFullscreenAction;

  /// No description provided for @muteAction.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteAction;

  /// No description provided for @unmuteAction.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteAction;

  /// No description provided for @videoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the video.'**
  String get videoLoadFailed;

  /// No description provided for @postVideoSemantics.
  ///
  /// In en, this message translates to:
  /// **'Video, {duration}'**
  String postVideoSemantics(String duration);

  /// No description provided for @videoSelectedHint.
  ///
  /// In en, this message translates to:
  /// **'Video of up to 60 s. Location data is removed.'**
  String get videoSelectedHint;

  /// No description provided for @videoLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the video…'**
  String get videoLoading;

  /// No description provided for @videoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoLabel;

  /// No description provided for @videoTooFast.
  ///
  /// In en, this message translates to:
  /// **'You can post another video in {minutes} min.'**
  String videoTooFast(int minutes);
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
