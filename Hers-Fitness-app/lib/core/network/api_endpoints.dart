class ApiEndpoints {
  const ApiEndpoints._();

  static const signIn = '/api/auth/login';
  static const refreshToken = '/api/auth/refresh-token';
  static const verifyEmail = '/api/auth/verify-email';
  static const resendVerification = '/api/auth/resend-verification';
  static const memberSignUp = '/api/auth/register';
  static const trainerSignUp = '/api/auth/register/trainer';
  static const forgotPassword = '/api/auth/forgot-password';
  static const verifyPasswordResetOtp = '/api/auth/verify-password-reset-otp';
  static const resetPassword = '/api/auth/reset-password';
  static const logout = '/api/auth/logout';
  static const identityVerification = '/identity-verification';
  static const users = '/api/users';
  static const currentUser = '/api/users/me';
  static const memberWeeklyActivity = '/api/users/member/weekly-activity';
  static const memberMonthlyActivity = '/api/users/member/monthly-activity';
  static const memberYearlyActivity = '/api/users/member/yearly-activity';
  static const memberDailyActivity = '/api/users/member/daily-activity';
  static const memberAssessment = '/api/users/member-assessment';
  static const memberUpdateProfile = '/api/users/member/profile';
  static const memberProfileImages = '/api/users/member/profile/images';
  static const memberTransactions = '/api/users/member/transactions';
  static const memberReferral = '/api/users/member/referral';
  static const memberAccount = '/api/users/member/account';
  static String staticContent(String key) => '/api/static-content/$key';
  static const helpTickets = '/api/help-tickets';
  static const helpTicketsMy = '/api/help-tickets/my';
  static String helpTicketById(String id) => '/api/help-tickets/my/$id';
  static const trainerClasses = '/api/trainer/classes';
  static const trainerDashboardStats = '/api/trainer/dashboard/stats';
  static const trainerDashboardEarnings = '/api/trainer/dashboard/earnings';
  static const trainerDashboardTopClasses =
      '/api/trainer/dashboard/top-classes';
  static const trainerNextClass = '/api/trainer/classes/next';
  static String trainerClassById(String id) => '/api/trainer/classes/$id';
  static String trainerClassReschedule(String id) =>
      '/api/trainer/classes/$id/reschedule';
  static const trainerSchedule = '/api/trainer/schedule';
  static String trainerBookingCheckIn(String id) =>
      '/api/trainer/bookings/$id/check-in';
  static String trainerBookingComplete(String id) =>
      '/api/trainer/bookings/$id/complete';
  static String trainerBookingReschedule(String id) =>
      '/api/trainer/bookings/$id/reschedule';
  static String trainerBookingRescheduleAccept(String id) =>
      '/api/trainer/bookings/$id/reschedule/accept';
  static const memberClasses = '/api/member/classes';
  static String memberClassBookings(String id) =>
      '/api/member/classes/$id/bookings';
  static String memberStripePaymentIntent(String paymentId) =>
      '/api/member/booking-payments/$paymentId/stripe-payment-intent';
  static String memberBookingPaymentConfirm(String paymentId) =>
      '/api/member/booking-payments/$paymentId/confirm';
  static String memberBookingPaymentFail(String paymentId) =>
      '/api/member/booking-payments/$paymentId/fail';
  static const memberBookedClasses = '/api/member/booked-classes';
  static const memberBookings = '/api/member/bookings';
  static const memberNextBooking = '/api/member/bookings/next';
  static const memberNextWorkouts = '/api/member/workouts/next';
  static String memberBookingReschedule(String id) =>
      '/api/member/bookings/$id/reschedule';
  static String memberBookingRescheduleAccept(String id) =>
      '/api/member/bookings/$id/reschedule/accept';
  static String memberBookingComplete(String id) =>
      '/api/member/bookings/$id/complete';
  static String memberBookingCheckIn(String id) =>
      '/api/member/bookings/$id/check-in';
  // ── Trainer profile management ────────────────────────────────────────────
  static const trainerUpdateProfile = '/api/users/trainer/profile';
  static const trainerProfileImages = '/api/users/trainer/profile/images';
  static const trainerTransactions = '/api/users/trainer/transactions';
  static const trainerAccount = '/api/users/trainer/account';

  // ── Trainer payout (Stripe Connect) ───────────────────────────────────────
  static const trainerPayoutStatus = '/api/users/trainer/payout/status';
  static const trainerPayoutOnboardingLink =
      '/api/users/trainer/payout/onboarding-link';

  // ── Notification preferences ──────────────────────────────────────────────
  static const notificationPreferences = '/api/notifications/preferences';

  // ── FAQs ──────────────────────────────────────────────────────────────────
  static const faqs = '/api/faqs';

  static const trainerBaseLocation = '/api/location/trainer/base';
  static const trainerLiveLocation = '/api/location/trainer/live';
  static const trainerOnlineStatus = '/api/location/trainer/status';
  static const memberLocation = '/api/location/member';
  static const nearbyTrainers = '/api/trainers/nearby';
  static const searchTrainers = '/api/trainers/search';
  static String apiTrainerDetails(String id) => '/api/trainers/$id';
  static String trainerOverview(String trainerUserId) =>
      '/api/trainers/$trainerUserId/overview';
  static String trainerAvailability(String trainerUserId) =>
      '/api/trainers/$trainerUserId/availability';
  static const chatConversations = '/api/chat/conversations';
  static String chatConversationMessages(String conversationId) =>
      '/api/chat/conversations/$conversationId/messages';
  static String chatConversationMessageImage(String conversationId) =>
      '/api/chat/conversations/$conversationId/messages/image';
  static String chatConversationSeen(String conversationId) =>
      '/api/chat/conversations/$conversationId/seen';
  static const notifications = '/api/notifications';
  static const notificationUnreadCount = '/api/notifications/unread-count';
  static const notificationDeviceTokens = '/api/notifications/device-tokens';
  static String notificationRead(String notificationId) =>
      '/api/notifications/$notificationId/read';
  static const notificationsReadAll = '/api/notifications/read-all';
  static String notificationDelete(String notificationId) =>
      '/api/notifications/$notificationId';
  static const notificationsDeleteAll = '/api/notifications/all';
  static const notificationTestPush = '/api/notifications/test-push';
  static String trainerReviews(String trainerUserId) =>
      '/api/reviews/trainers/$trainerUserId';
  static const memberTrainerReviews = '/api/reviews/member/trainer-reviews';
  static const countries = '/api/countries';
  static String countryByIso3(String codeIso3) =>
      '/api/countries/code-iso3/$codeIso3';
  static String countryByCode(String code) => '/api/countries/code/$code';

  static const trainers = '/trainers';
  static const trainerDetails = '/trainers';
  static const classes = '/classes';
}
