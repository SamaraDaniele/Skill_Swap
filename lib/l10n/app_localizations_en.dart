// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Skill Swap';

  @override
  String get authTagline => 'Teach what you know. Learn what you love.';

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signUpTitle => 'Create your account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInAction => 'Sign in';

  @override
  String get signUpAction => 'Create account';

  @override
  String get newHerePrompt => 'New here?';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get forgotPassword => 'Forgot my password';

  @override
  String get orSeparator => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get socialSignInSoon =>
      'This sign-in option is coming soon. For now, use email and password.';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordBody =>
      'Enter your email and we will send you a link to choose a new password.';

  @override
  String get resetPasswordSent =>
      'If an account exists for that email, the link is on its way.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get validationEmail => 'Enter a valid email';

  @override
  String get validationPassword => 'Use at least 6 characters';

  @override
  String get validationRequired => 'Required field';

  @override
  String get validationPickSkill => 'Pick at least one skill';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get errorEmailInUse => 'This email is already registered.';

  @override
  String get errorWeakPassword => 'Choose a stronger password.';

  @override
  String get errorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get errorPermission => 'You don\'t have permission for this action.';

  @override
  String get errorInvalidImage =>
      'This image can\'t be used. Try another photo.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get retryAction => 'Try again';

  @override
  String get profileSetupTitle => 'Set up your profile';

  @override
  String get profileSetupSubtitle =>
      'Tell people what you can teach and what you want to learn.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get nameLabel => 'Name';

  @override
  String get bioLabel => 'About you';

  @override
  String get bioHint => 'A short intro, availability, preferred format…';

  @override
  String get photoAddAction => 'Add photo';

  @override
  String get photoChangeAction => 'Change photo';

  @override
  String get photoRemoveAction => 'Remove photo';

  @override
  String get photoProcessing => 'Preparing photo…';

  @override
  String get photoHint =>
      'Optional. A square crop of your photo; location data is removed.';

  @override
  String get teachSectionTitle => 'I can teach';

  @override
  String get learnSectionTitle => 'I want to learn';

  @override
  String get saveAction => 'Save';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get navDiscover => 'Match';

  @override
  String get navMatches => 'Chats';

  @override
  String get navProfile => 'Profile';

  @override
  String get discoverEmptyTitle => 'No one new for now';

  @override
  String get discoverEmptyBody =>
      'Add more skills to your profile or come back later.';

  @override
  String get refreshAction => 'Refresh';

  @override
  String get likeAction => 'Interested';

  @override
  String get passAction => 'Skip';

  @override
  String get teachesLabel => 'Teaches';

  @override
  String get wantsLabel => 'Wants to learn';

  @override
  String compatibility(int percent) {
    return '$percent% match';
  }

  @override
  String get matchDialogTitle => 'It\'s a match!';

  @override
  String matchDialogBody(String name) {
    return 'You and $name can start chatting now.';
  }

  @override
  String get openChatAction => 'Send message';

  @override
  String get keepExploringAction => 'Keep exploring';

  @override
  String get matchesEmptyTitle => 'No matches yet';

  @override
  String get matchesEmptyBody =>
      'Show interest in profiles on Discover. When it\'s mutual, they show up here.';

  @override
  String get matchesNoMessages => 'Say hi to start the exchange';

  @override
  String get chatHint => 'Message';

  @override
  String get sendAction => 'Send';

  @override
  String get chatEmpty =>
      'Agree on topics, format and a time that works for both of you.';

  @override
  String get signOutAction => 'Sign out';

  @override
  String get editProfileAction => 'Edit profile';

  @override
  String get skillExcel => 'Excel';

  @override
  String get skillEnglish => 'English';

  @override
  String get skillSpanish => 'Spanish';

  @override
  String get skillProgramming => 'Programming';

  @override
  String get skillPython => 'Python';

  @override
  String get skillGuitar => 'Guitar';

  @override
  String get skillPiano => 'Piano';

  @override
  String get skillMath => 'Math';

  @override
  String get skillPhysics => 'Physics';

  @override
  String get skillChemistry => 'Chemistry';

  @override
  String get skillPhotoEditing => 'Photo editing';

  @override
  String get skillVideoEditing => 'Video editing';

  @override
  String get skillCooking => 'Cooking';

  @override
  String get skillCrafts => 'Crafts';

  @override
  String get skillDrawing => 'Drawing';

  @override
  String get skillWriting => 'Writing';

  @override
  String get skillPublicSpeaking => 'Public speaking';

  @override
  String get skillPhotography => 'Photography';

  @override
  String get skillDesign => 'Design';

  @override
  String get skillMarketing => 'Marketing';

  @override
  String get moreOptions => 'More options';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get unmatchAction => 'Undo match';

  @override
  String get unmatchConfirmTitle => 'Undo this match?';

  @override
  String get unmatchConfirmBody =>
      'The conversation will be closed for both of you. This can\'t be undone.';

  @override
  String get matchClosedDone => 'Match undone';

  @override
  String get blockAction => 'Block';

  @override
  String blockConfirmTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get blockConfirmBody =>
      'You won\'t match again and no more messages can be sent. This can\'t be undone.';

  @override
  String get blockDone => 'Profile blocked';

  @override
  String get reportAction => 'Report';

  @override
  String get reportProfileTooltip => 'Report profile';

  @override
  String reportTitle(String name) {
    return 'Report $name';
  }

  @override
  String get reportIntro =>
      'Your report is confidential. The profile will also be blocked for you.';

  @override
  String get reportReasonHarassment => 'Harassment or threats';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonFake => 'Fake profile';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportDetailsLabel => 'Details (optional)';

  @override
  String get reportPickReason => 'Choose a reason';

  @override
  String get reportSubmitAction => 'Report and block';

  @override
  String get reportDone =>
      'Report sent. Thanks for helping keep the community safe.';

  @override
  String get chatClosedNotice => 'This conversation has ended.';

  @override
  String get consentTitle => 'Before you continue';

  @override
  String get consentBody =>
      'Skill Swap connects people who want to exchange knowledge. To keep everyone safe, all members must be adults and follow the community rules.';

  @override
  String get consentCheckbox =>
      'I am 18 or older and accept the Terms and Community rules';

  @override
  String get consentRequired => 'Accept to continue';

  @override
  String get continueAction => 'Continue';

  @override
  String get readTermsAction => 'Read the terms';

  @override
  String get termsTitle => 'Terms and community rules';

  @override
  String get termsBody =>
      '• You must be 18 or older.\n• Treat everyone with respect: harassment, threats, hate speech and sexual content are not allowed.\n• Use your real name and describe your skills honestly.\n• No spam, scams or hidden charges.\n• Don\'t share other people\'s personal data.\n• Prefer public places or video calls for your sessions.\n\nYou can undo a match, block or report anyone from the chat menu or the profile card. Reports are confidential and reviewed by the project team; breaking these rules can lead to account removal.\n\nThis is a summary written for an academic project and is not a legally reviewed agreement.';

  @override
  String get matchTitle => 'Match';

  @override
  String get notificationsSoon => 'Notifications (coming soon)';

  @override
  String get openProfile => 'Your profile';

  @override
  String get undoAction => 'Undo last skip';

  @override
  String get saveForLaterSoon => 'Save for later (coming soon)';

  @override
  String get knowledgeMatchTitle => 'Knowledge match';

  @override
  String knowledgeExchange(String teach, String learn, String name) {
    return 'You teach $teach and learn $learn with $name.';
  }

  @override
  String knowledgeTeach(String skill, String name) {
    return 'You know $skill and $name wants to learn it!';
  }

  @override
  String knowledgeLearn(String name, String skill) {
    return '$name knows $skill, which you want to learn!';
  }

  @override
  String skillPair(String first, String second) {
    return '$first and $second';
  }

  @override
  String profileCardLabel(String name) {
    return 'Profile of $name';
  }

  @override
  String get navMySkills => 'My Skills';

  @override
  String get goalLabel => 'Goal';

  @override
  String goalLearn(String skill) {
    return 'Learn $skill';
  }

  @override
  String get compatibilityLabel => 'Affinity';

  @override
  String get profileDetailsAction => 'View profile details';

  @override
  String newMatchesBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches with no messages yet',
      one: '1 match with no messages yet',
    );
    return '$_temp0';
  }

  @override
  String get navCommunity => 'Community';

  @override
  String get communityTitle => 'Community';

  @override
  String get communitySubtitle => 'Share, learn and inspire.';

  @override
  String get searchAction => 'Search';

  @override
  String get newPostAction => 'New post';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String unreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
    );
    return '$_temp0';
  }

  @override
  String get feedForYou => 'For you';

  @override
  String get feedFollowing => 'Following';

  @override
  String get feedSkills => 'Skills';

  @override
  String get feedProjects => 'Projects';

  @override
  String get feedEmptyTitle => 'No posts yet';

  @override
  String get feedEmptyBody =>
      'Be the first to share a project, a tip or a question.';

  @override
  String get feedFollowingEmptyTitle => 'Nothing from people you follow';

  @override
  String get feedFollowingEmptyBody =>
      'Follow members to see their posts here.';

  @override
  String get feedSkillsEmptyTitle => 'No posts about your skills';

  @override
  String get feedSkillsEmptyBody =>
      'Posts about the skills you teach or want to learn appear here.';

  @override
  String get feedProjectsEmptyTitle => 'No projects yet';

  @override
  String get feedProjectsEmptyBody => 'Show what you built: post a project.';

  @override
  String get searchPeopleAction => 'Find people';

  @override
  String get feedEnd => 'You\'re all caught up';

  @override
  String get loadMoreFailed => 'Couldn\'t load more. Tap to try again';

  @override
  String get loadMoreAction => 'Load more';

  @override
  String get loadingPosts => 'Loading posts';

  @override
  String get timeNow => 'now';

  @override
  String timeMinutes(int n) {
    return '$n min ago';
  }

  @override
  String timeHours(int n) {
    return '$n h ago';
  }

  @override
  String timeDays(int n) {
    return '$n d ago';
  }

  @override
  String get postTypeProject => 'Project';

  @override
  String get postTypeTip => 'Tip';

  @override
  String get postTypeQuestion => 'Question';

  @override
  String get postTypeAchievement => 'Achievement';

  @override
  String get postTypeWork => 'Work';

  @override
  String hashtagSemantics(String tag) {
    return 'Hashtag $tag';
  }

  @override
  String get memberFallbackName => 'Member';

  @override
  String teachesSkill(String skill) {
    return 'Teaches $skill';
  }

  @override
  String openMemberProfile(String name) {
    return 'Open $name\'s profile';
  }

  @override
  String get postEdited => 'edited';

  @override
  String get postMenuTooltip => 'Post options';

  @override
  String get readMore => 'Read more';

  @override
  String postImageSemantics(int index, int total) {
    return 'Image $index of $total';
  }

  @override
  String get imageLoadFailed => 'Tap to retry';

  @override
  String get learnPanelTitle => 'Skill available to teach';

  @override
  String learnPanelBody(String name, String skills) {
    return '$name can teach $skills.';
  }

  @override
  String learnWithAction(String name) {
    return 'I want to learn with $name';
  }

  @override
  String get learnPending => 'Interest sent · waiting for an answer';

  @override
  String learnConfirmTitle(String name) {
    return 'Learn with $name?';
  }

  @override
  String learnConfirmBody(String name) {
    return 'This sends your interest through Match, like a swipe right. $name will be notified that you want to learn from this post. If $name is also interested in you, you match and the chat opens.';
  }

  @override
  String get learnConfirmAction => 'Send interest';

  @override
  String learnSent(String name) {
    return 'Interest sent to $name. You will match if the interest is mutual.';
  }

  @override
  String get commentAction => 'Comment';

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: 'no comments',
    );
    return '$_temp0';
  }

  @override
  String likesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
      zero: 'no likes',
    );
    return '$_temp0';
  }

  @override
  String get likePostAction => 'Like';

  @override
  String get unlikeAction => 'Unlike';

  @override
  String get shareAction => 'Share';

  @override
  String get unsaveAction => 'Remove from saved';

  @override
  String get postSaved => 'Saved';

  @override
  String get postUnsaved => 'Removed from saved';

  @override
  String get editPostAction => 'Edit post';

  @override
  String get deletePostAction => 'Delete post';

  @override
  String get deletePostTitle => 'Delete this post?';

  @override
  String get deletePostBody =>
      'The post and its images are removed for everyone. This cannot be undone.';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get copyLinkAction => 'Copy link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get reportPostAction => 'Report post';

  @override
  String get reportCommentAction => 'Report comment';

  @override
  String get reportMemberAction => 'Report member';

  @override
  String blockMemberAction(String name) {
    return 'Block $name';
  }

  @override
  String communityBlockBody(String name) {
    return 'You won\'t see $name\'s posts or comments, they can\'t interact with your content, and you won\'t match. This cannot be undone.';
  }

  @override
  String get reportPostTitle => 'Report post';

  @override
  String get reportCommentTitle => 'Report comment';

  @override
  String get contentReportIntro =>
      'Your report is confidential and will be reviewed by the moderators.';

  @override
  String get contentReportDone =>
      'Report sent. Thank you for keeping the community safe.';

  @override
  String get reportReasonOffensive => 'Offensive content';

  @override
  String get reportReasonScam => 'Scam';

  @override
  String get sendInChat => 'Send in a chat';

  @override
  String get shareNoChats =>
      'You have no open chats yet. Copy the link instead.';

  @override
  String sharePostTitle(String name) {
    return 'Send to $name?';
  }

  @override
  String get sharePostBody =>
      'A message with the link to this post will be sent in your chat.';

  @override
  String sharedPostMessage(String link) {
    return 'Check out this post on Skill Swap: $link';
  }

  @override
  String postSharedTo(String name) {
    return 'Sent to $name';
  }

  @override
  String get openSharedPost => 'Open post';

  @override
  String get postTitle => 'Post';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentsEmpty => 'No comments yet. Start the conversation!';

  @override
  String get loadMoreComments => 'Load more comments';

  @override
  String get showReplies => 'Show replies';

  @override
  String get hideReplies => 'Hide replies';

  @override
  String get replyAction => 'Reply';

  @override
  String replyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get commentHint => 'Add a comment…';

  @override
  String get commentMenuTooltip => 'Comment options';

  @override
  String get commentTooFast => 'Wait a moment before commenting again.';

  @override
  String get deleteCommentAction => 'Delete comment';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get postNotFoundTitle => 'Post unavailable';

  @override
  String get postNotFoundBody =>
      'It may have been deleted, or the link is wrong.';

  @override
  String get backToCommunity => 'Back to Community';

  @override
  String get newPostTitle => 'New post';

  @override
  String get editPostTitle => 'Edit post';

  @override
  String get previewAction => 'Preview';

  @override
  String get previewTitle => 'Preview';

  @override
  String get addImagesAction => 'Add images';

  @override
  String get removeImageAction => 'Remove image';

  @override
  String imagesHint(int max) {
    return 'Up to $max images. We resize them and remove location data.';
  }

  @override
  String get imagePickFailed => 'Couldn\'t open your photos.';

  @override
  String imagesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images could not be used',
      one: '1 image could not be used',
    );
    return '$_temp0';
  }

  @override
  String get editImagesLocked =>
      'Images cannot be changed after publishing. To change them, delete the post and publish again.';

  @override
  String get postDescriptionLabel => 'Description';

  @override
  String get postDescriptionHint =>
      'Tell us about your project, tip or question…';

  @override
  String get postTypeLabel => 'Type';

  @override
  String postSkillsLabel(int count, int max) {
    return 'Related skills ($count/$max)';
  }

  @override
  String get postSkillsHint =>
      'From your profile. Skills you teach show the \"learn with you\" button.';

  @override
  String postSkillsMax(int max) {
    return 'Choose up to $max skills.';
  }

  @override
  String get postTagsLabel => 'Hashtags';

  @override
  String get postTagsHint => '#design #ui';

  @override
  String postTagsHelper(int count, int max) {
    return '$count/$max valid tags (letters, numbers, _)';
  }

  @override
  String get visibilityLabel => 'Who can see it?';

  @override
  String get visibilityPublic => 'Public';

  @override
  String get visibilityPublicBody => 'All Skill Swap members.';

  @override
  String get publishAction => 'Publish';

  @override
  String get saveChangesAction => 'Save changes';

  @override
  String preparingImages(int done, int total) {
    return 'Preparing images $done/$total…';
  }

  @override
  String get sendingPost => 'Sending…';

  @override
  String get postEmptyError => 'Write something or add an image.';

  @override
  String get postTooLongError => 'The description is too long.';

  @override
  String postTooFast(int seconds) {
    return 'Wait $seconds s before publishing again.';
  }

  @override
  String get postPublished => 'Post published';

  @override
  String get postUpdated => 'Post updated';

  @override
  String get discardPostTitle => 'Discard post?';

  @override
  String get discardPostBody => 'What you wrote will be lost.';

  @override
  String get keepEditingAction => 'Keep editing';

  @override
  String get discardAction => 'Discard';

  @override
  String get errorInvalidPost => 'Check the post: it is empty or too long.';

  @override
  String get memberMenuTooltip => 'More options';

  @override
  String memberBlockedTitle(String name) {
    return 'You blocked $name';
  }

  @override
  String get memberBlockedBody => 'Their content is hidden for you.';

  @override
  String get memberNotFound => 'Member not found';

  @override
  String get portfolioTitle => 'Posts and portfolio';

  @override
  String get portfolioEmpty => 'No posts yet.';

  @override
  String get portfolioEmptyMine =>
      'Your posts appear here. Share your first project!';

  @override
  String get statPosts => 'Posts';

  @override
  String get statFollowers => 'Followers';

  @override
  String get statFollowing => 'Following';

  @override
  String get followAction => 'Follow';

  @override
  String get followingAction => 'Following';

  @override
  String get messageAction => 'Message';

  @override
  String openPostSemantics(String text) {
    return 'Open post: $text';
  }

  @override
  String get followersEmpty => 'No followers yet';

  @override
  String get followingEmpty => 'Not following anyone yet';

  @override
  String get myPortfolioAction => 'My posts';

  @override
  String get savedTitle => 'Saved';

  @override
  String get savedEmptyTitle => 'Nothing saved yet';

  @override
  String get savedEmptyBody =>
      'Tap the bookmark on a post to keep it here. Only you see this list.';

  @override
  String get searchHint => 'Search people, posts or #tags';

  @override
  String get searchPeople => 'People';

  @override
  String get searchPosts => 'Posts';

  @override
  String get searchSkills => 'Skills';

  @override
  String get searchPeopleHint => 'Type at least 2 letters of a name.';

  @override
  String searchNoPeople(String term) {
    return 'No one found for \"$term\"';
  }

  @override
  String get searchPeopleLimit =>
      'The search matches the beginning of the name.';

  @override
  String get searchPostsHint => 'Search a word or a #tag.';

  @override
  String searchNoPosts(String term) {
    return 'No posts with \"$term\"';
  }

  @override
  String get searchPostsLimit => 'The search uses one word or tag at a time.';

  @override
  String get searchSkillsHint =>
      'Choose a skill to see who teaches it and related posts.';

  @override
  String skillTeachersTitle(String skill) {
    return 'Who teaches $skill';
  }

  @override
  String get skillTeachersEmpty => 'No one teaches this skill yet.';

  @override
  String skillPostsTitle(String skill) {
    return 'Posts about $skill';
  }

  @override
  String get skillPostsEmpty => 'No posts about this skill yet.';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptyBody =>
      'Likes, comments, follows and learning requests appear here.';

  @override
  String get markAllReadAction => 'Mark all read';

  @override
  String get unreadLabel => 'unread';

  @override
  String notificationLike(String name) {
    return '$name liked your post';
  }

  @override
  String notificationComment(String name) {
    return '$name commented on your post';
  }

  @override
  String notificationReply(String name) {
    return '$name replied to your comment';
  }

  @override
  String notificationFollow(String name) {
    return '$name started following you';
  }

  @override
  String notificationLearn(String name) {
    return '$name wants to learn with you';
  }

  @override
  String get contentReportSubmit => 'Send report';

  @override
  String get deleteNotificationAction => 'Delete notification';

  @override
  String get postTypeKnowledge => 'Knowledge';

  @override
  String get errorInvalidVideo =>
      'Use an MP4 video of up to 60 seconds and 2.3 MB.';

  @override
  String get addVideoAction => 'Add video';

  @override
  String get removeVideoAction => 'Remove video';

  @override
  String get videoHint => 'Or 1 video of up to 60 s (MP4, up to 2.3 MB).';

  @override
  String get videoPickFailed => 'Could not open your videos.';

  @override
  String get preparingVideo => 'Preparing the video…';

  @override
  String get playVideoAction => 'Play video';

  @override
  String get pauseVideoAction => 'Pause video';

  @override
  String get replayVideoAction => 'Watch again';

  @override
  String get fullscreenAction => 'Full screen';

  @override
  String get exitFullscreenAction => 'Exit full screen';

  @override
  String get muteAction => 'Mute';

  @override
  String get unmuteAction => 'Unmute';

  @override
  String get videoLoadFailed => 'Could not load the video.';

  @override
  String postVideoSemantics(String duration) {
    return 'Video, $duration';
  }

  @override
  String get videoSelectedHint =>
      'Video of up to 60 s. Location data is removed.';

  @override
  String get videoLoading => 'Loading the video…';

  @override
  String get videoLabel => 'Video';

  @override
  String videoTooFast(int minutes) {
    return 'You can post another video in $minutes min.';
  }
}
