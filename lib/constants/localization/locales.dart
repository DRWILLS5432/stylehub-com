import 'package:flutter_localization/flutter_localization.dart';

const List<MapLocale> LOCALES = [
  MapLocale('en', LocaleData.EN),
  // MapLocale('uk', LocaleData.UK),
  MapLocale('ru', LocaleData.RU),
];

mixin LocaleData {
  static const String changeLanguage = 'Choose your language';
  static const String find = 'Find';
  static const String stylists = 'Stylists';
  static const String stylist = 'Stylist';
  static const String nearYou = 'Near You';
  static const String next = 'Next';
  static const String getStarted = 'Get Started';
  static const String createAccount = 'Create Account';
  static const String login = 'Login';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String selectRole = 'Select between customer and stylist';
  static const String register = 'Register';
  static const String customer = 'Customer';
  static const String termsAndConditions = 'Terms & Conditions apply';
  static const String welcomeBack = 'Welcome Back';
  static const String passwordRequired = 'Password field is required';
  static const String firstNameRequired = 'First name field is required';
  static const String lastNameRequired = 'Last name field is required';
  static const String emailRequired = 'Email field is required';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordInvalid = 'Password must be at least 6 characters';
  static const String roleRequired = 'Role field is required';
  static const String forgotPassword = 'Change Password?';
  static const String goToAdmin = 'Go to Admin';
  static const String sendOTP = 'Send Code';
  static const String enterRegisteredEmail = 'Enter Registered Email Address';
  static const String resetPassword = 'Reset Password';
  static const String newPassword = 'Enter New Password';
  static const String confirmNewPassword = 'Confirm New Password';
  static const String emailAddress = 'Email Address';
  static const String resendCode = 'Resend Code';
  static const String confirm = 'Confirm';
  static const String checkEmail = 'Check your email, A reset link will be sent to you to reset your password';
  static const String seconds = 'Seconds';
  static const String editProfile = 'Edit Profile';
  static const String logout = 'Logout';
  static const String changePassword = 'Forgot Password';
  static const String updateService = 'Update Service';
  static const String editProfileDetail = 'Update your profile details';
  static const String updateServiceDetail = 'Update services you render';
  static const String settings = 'Settings';
  static const String updateSettings = 'Update your settings';
  static const String changePhoneLanguage = 'Change your system language';
  static const String category = 'Categories';
  static const String findProfessional = 'Find beauty professionals near you';
  static const String likes = 'Likes';
  static const String appointments = 'Appointments';
  static const String view = 'view';
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String wantToCancelAppointment = 'Are you sure you want to cancel your appointment?';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String changeProfilePics = 'Change profile picture';
  static const String personalDetails = 'Personal Details';
  static const String specialistDetails = 'Specialist Details';
  static const String appSettings = 'App Settings';
  static const String language = 'Language';
  static const String notifications = 'Notifications';
  static const String profession = 'Profession';
  static const String yearsOfExperience = 'Years of Experience';
  static const String serviceCategory = 'Service Category';
  static const String bio = 'Bio';
  static const String previousWork = 'Previous Work';
  static const String edit = 'Edit';
  static const String uploadImages = 'Upload Images';
  static const String note = 'N:B All photos uploaded must be edited in the format before and After  or else the photos will be rejected by our platform review team.';
  static const String phoneNumber = 'Phone Number';
  static const String serviceProvide = 'Services I provide';
  static const String review = 'Review';
  static const String callMe = 'Call Me';
  static const String reviews = 'Reviews';
  static const String leaveA = 'Leave a';
  static const String howDidItGo = 'How did your Appointment go?';
  static const String takeAMomentToRate = 'Please take a moment to rate stylists and leave a review';
  static const String writeYourRevHere = 'Write your Review here';
  static const String yourAddress = 'Set your home address in Settings for easier scheduling in the future. Enable Location to show stylists in your city.';
  static const String city = 'City';
  static const String pickService = 'Pick a service categories to attract clients looking for your services';
  static const String selectedCategory = 'Selected Category';
  static const String selectedService = 'The selected services you have picked will be displayed on your profile page to get clients.';
  static const String services = 'Services';
  static const String priceRange = 'Price Range';
  static const String price = 'Price';
  static const String accept = 'Accept';
  static const String serviceName = 'Service Name';
  static const String goToClient = 'Ready to go to Client';
  static const String save = 'Save';
  static const String create = 'Create';
  static const String update = 'Update';
  static const String youCanUploadMore = 'You can Upload another photo after saving this one';
  static const String goBack = 'Return';
  static const String address = 'Address';
  static const String availableTimeSlots = 'Available Time Slots';
  static const String addressOfMeeting = 'Address of Meeting';
  static const String yurAddress = 'Your Address';
  static const String specialistAddress = 'Specialist Address';
  static const String makeAppointment = 'Make Appointment';
  static const String date = 'Date';
  static const String time = 'Time';
  static const String youCanUploadMoreImages = 'You can Upload another photo after saving this one';
  static const String admin = 'Admin';
  static const String loginFailed = 'Login Failed';
  static const String loginAsAdmin = 'Login as Admin';
  static const String name = 'Name';
  static const String enterName = 'Enter Name';
  static const String nameRequired = 'Name field is required';
  static const String nameInvalid = 'Please enter a valid name';
  static const String totalUsers = 'Total Users';
  static const String help = 'Help';
  static const String subject = 'Subject';
  static const String message = 'Message';
  static const String submit = 'Submit';
  static const String specialistNotReady = 'Specialist is not ready to go your address';

// FOR ENGLISH
  static const Map<String, dynamic> EN = {
    changeLanguage: 'Choose your language ',
    find: 'Find',
    stylists: 'Stylists',
    nearYou: 'Near You',
    next: 'Next',
    getStarted: 'Get Started',
    createAccount: 'Create Account',
    login: 'Login',
    email: 'Email',
    password: 'Password',
    firstName: 'First Name',
    lastName: 'Last Name',
    selectRole: 'Select between customer and stylist',
    register: 'Register',
    termsAndConditions: 'Terms & Conditions apply',
    stylist: 'Stylist',
    welcomeBack: 'Welcome Back',
    customer: 'Customer',
    passwordRequired: 'Password field is required',
    firstNameRequired: 'First name field is required',
    lastNameRequired: 'Last name field is required',
    emailRequired: 'Email field is required',
    emailInvalid: 'Please enter a valid email',
    passwordInvalid: 'Password must be at least 6 characters',
    roleRequired: 'Role field is required',
    forgotPassword: 'Forgot Password?',
    sendOTP: 'Send Code',
    enterRegisteredEmail: 'Enter Registered Email Address',
    resetPassword: 'Reset Password',
    newPassword: 'Enter New Password',
    confirmNewPassword: 'Confirm New Password',
    emailAddress: 'Email Address',
    resendCode: 'Resend Code',
    confirm: 'Confirm',
    checkEmail: 'Check your email, A reset link will be sent to you to reset your password',
    seconds: 'Seconds',
    editProfile: 'Edit Profile',
    logout: 'Logout',
    changePassword: 'Change Password',
    updateService: 'Update Service',
    editProfileDetail: 'Update your profile details',
    updateServiceDetail: 'Update services you render',
    settings: 'Settings',
    updateSettings: 'Update your settings',
    changePhoneLanguage: 'Change your system language',
    category: 'Categories',
    findProfessional: 'Find beauty professionals near you',
    likes: 'Likes',
    appointments: 'Appointments',
    view: 'view',
    ok: 'OK',
    cancel: 'Cancel',
    wantToCancelAppointment: 'Are you sure you want to cancel your appointment?',
    yes: 'Yes',
    no: 'No',
    changeProfilePics: 'Change profile picture',
    personalDetails: 'Personal Details',
    specialistDetails: 'Specialist Details',
    appSettings: 'App Settings',
    language: 'Language',
    notifications: 'Notifications',
    profession: 'Profession',
    yearsOfExperience: 'Years of Experience',
    serviceCategory: 'Service Category',
    bio: 'Bio',
    previousWork: 'Previous Work',
    edit: 'Edit',
    uploadImages: 'Upload Images',
    note: 'N:B All photos uploaded must be edited in the format before and After  or else the photos will be rejected by our platform review team.',
    phoneNumber: 'Phone Number',
    serviceProvide: 'Services I provide',
    review: 'Review',
    callMe: 'Call Me',
    reviews: 'Reviews',
    leaveA: 'Leave a',
    howDidItGo: 'How did your Appointment go?',
    takeAMomentToRate: 'Please take a moment to rate stylists and leave a review',
    writeYourRevHere: 'Write your Review here',
    yourAddress: 'Set your home address in Settings for easier scheduling in the future. Enable Location to show stylists in your city.',
    city: 'City',
    pickService: 'Pick a service categories to attract clients looking for your services',
    selectedCategory: 'Selected Category',
    selectedService: 'The selected services you have picked will be displayed on your profile page to get clients.',
    services: 'Services',
    priceRange: 'Price Range',
    price: 'Price',
    accept: 'Accept',
    serviceName: 'Service Name',
    goToClient: 'Ready to go to Client',
    save: 'Save',
    create: 'Create',
    update: 'Update',
    youCanUploadMore: 'You can Upload another photo after saving this one',
    goBack: 'Return',
    address: 'Address',
    availableTimeSlots: 'Available Time Slots',
    addressOfMeeting: 'Address of Meeting',
    yurAddress: 'Your Address',
    specialistAddress: 'Specialist Address',
    makeAppointment: 'Make Appointment',
    goToAdmin: 'Go to Admin',
    admin: 'Admin',
    loginAsAdmin: 'Login as Admin',
    loginFailed: 'Login Failed',
    name: 'Name',
    enterName: 'Enter Name',
    nameRequired: 'Name field is required',
    nameInvalid: 'Please enter a valid name',
    totalUsers: 'Total Users',
    help: 'Help',
    subject: 'Subject',
    message: 'Message',
    submit: 'Submit',
    specialistNotReady: 'Specialist is not ready to go your address',
  };

  // static const Map<String, dynamic> UK = {
  //   changeLanguage: 'Виберіть мову',
  //   find: 'Пошук',
  //   stylists: 'Стилісти',
  //   nearYou: 'Поруч з вами',
  //   next: 'Далі',
  //   getStarted: 'Почніть',
  //   createAccount: 'Створити обліковий запис',
  //   login: 'Увійти',
  //   email: 'Електронна пошта',
  //   password: 'Пароль',
  //   firstName: "Ім'я",
  //   lastName: 'Прізвище',
  //   selectRole: 'Оберіть між клієнтом та стилістом',
  //   register: 'Зареєструватися',
  //   termsAndConditions: 'Умови використання',
  //   stylist: 'Стиліст',
  //   welcomeBack: 'З поверненням',
  //   customer: 'Клієнт',
  //   passwordRequired: 'Поле "Пароль" обов’язкове для заповнення',
  //   firstNameRequired: "Поле 'Ім'я' обов’язкове для заповнення",
  //   lastNameRequired: "Поле 'Прізвище' обов’язкове для заповнення",
  //   emailRequired: 'Поле "Електронна пошта" обов’язкове для заповнення',
  //   emailInvalid: 'Будь ласка, введіть коректну електронну пошту',
  //   passwordInvalid: 'Пароль повинен містити не менше 6 символів',
  //   roleRequired: 'Поле "Роль" обов’язкове для заповнення',
  //   forgotPassword: 'Забули пароль?',
  //   sendOTP: 'Відправити OTP',
  //   enterRegisteredEmail: 'Введіть зареєстровану електронну пошту',
  //   resetPassword: 'Скинути пароль',
  //   newPassword: 'Введіть новий пароль',
  //   confirmNewPassword: 'Підтвердіть новий пароль',
  //   emailAddress: 'Електронна пошта',
  //   resendCode: 'Надіслати код ще раз',
  //   confirm: 'Підтвердити',
  //   checkEmail: 'Перевірте свою електронну пошту, OTP було відправлено вам, щоб скинути ваш пароль',
  //   seconds: 'Секунд',
  //   editProfile: 'Редагувати профіль',
  //   logout: 'Вихід',
  //   changePassword: 'Змінити пароль',
  //   updateService: 'Оновити послугу',
  //   editProfileDetail: 'Оновити деталі профілю',
  //   updateServiceDetail: 'Оновити послуги, які ви робите',
  //   settings: 'Налаштування',
  //   updateSettings: 'Оновити налаштування',
  //   changePhoneLanguage: 'Змінити мову телефону',
  //   category: 'Категорії',
  //   findProfessional: 'Знайти професіоналів бізнесу',
  //   likes: 'Лайки',
  //   appointments: 'Записи',
  //   view: 'переглянути',
  //   ok: 'OK',
  //   cancel: 'Скасувати',
  //   wantToCancelAppointment: 'Ви впевнені, що хочете скасувати запис?',
  //   yes: 'Так',
  //   no: 'Ні',
  //   changeProfilePics: 'Змінити фото профілю',
  //   personalDetails: 'Персональні деталі',
  //   specialistDetails: 'Деталі спеціаліста',
  //   appSettings: 'Налаштування програми',
  //   language: 'Мова',
  //   notifications: 'Повідомлення',
  //   profession: 'Професія',
  //   yearsOfExperience: 'Роки досвіду',
  //   serviceCategory: 'Категорія послуг',
  //   bio: 'Біографія',
  //   previousWork: 'Попередні роботи',
  //   edit: 'Редагувати',
  //   uploadImages: 'Завантажити зображення',
  //   note: 'Замітка',
  //   phoneNumber: 'Номер телефону',
  //   serviceProvide: 'Послуги, які ви робите',
  //   review: 'Відгук',
  //   callMe: 'Зателефонувати мені',
  //   reviews: 'Відгуки',
  //   leaveA: 'Залишити відгук',
  //   howDidItGo: 'Як це було?',
  //   takeAMomentToRate: 'Затримайтеся, щоб оцінити',
  //   writeYourRevHere: 'Напишіть свій відгук тут',
  //   yourAddress: "Встановіть свою домашню адресу в Налаштуваннях для зручнішого планування в майбутньому. Увімкніть геолокацію, щоб показати стилістів у вашому місті.",
  //   city: 'Місто',
  // };

  // FOR RUSSIAN
  static const Map<String, dynamic> RU = {
    changeLanguage: 'Выберите язык  ',
    find: 'Найти',
    stylists: 'Стилисты',
    nearYou: 'Рядом',
    next: 'Далее',
    getStarted: 'Начать',
    createAccount: 'Создать аккаунт',
    login: 'Войти',
    email: 'Электронная почта',
    password: 'Пароль',
    firstName: 'Имя',
    lastName: 'Фамилия',
    selectRole: 'Выберите между клиентом и стилистом',
    register: 'Регистрация',
    termsAndConditions: 'Правила и условия применяются',
    stylist: 'Стилист',
    welcomeBack: 'Добро пожаловать обратно',
    customer: 'Клиент',
    passwordRequired: 'Поле пароля обязательно',
    firstNameRequired: 'Поле имени обязательно',
    lastNameRequired: 'Поле фамилии обязательно',
    emailRequired: 'Поле электронной почты обязательно',
    emailInvalid: 'Пожалуйста, введите действительный адрес электронной почты',
    passwordInvalid: 'Пароль должен содержать не менее 6 символов',
    roleRequired: 'Поле роли обязательно',
    forgotPassword: 'Забыли пароль?',
    sendOTP: 'Отправить OTP',
    enterRegisteredEmail: 'Введите зарегистрированную электронную почту',
    resetPassword: 'Сбросить пароль',
    newPassword: 'Введите новый пароль',
    confirmNewPassword: 'Подтвердите новый пароль',
    emailAddress: 'Электронная почта',
    resendCode: 'Отправить код повторно',
    confirm: 'Подтвердить',
    checkEmail: 'Проверьте свою электронную почту, OTP был отправлен вам, чтобы сбросить ваш пароль',
    seconds: 'Секунд',
    editProfile: 'Редактировать профиль',
    logout: 'Выход',
    changePassword: 'Изменить пароль',
    updateService: 'Обновить услугу',
    editProfileDetail: 'Обновить детали профиля',
    updateServiceDetail: 'Обновить услуги, которые вы предоставляете',
    settings: 'Настройки',
    updateSettings: 'Обновить настройки',
    changePhoneLanguage: 'Изменить язык телефона',
    category: 'Категории',
    findProfessional: 'Найти профессионалов бизнеса',
    likes: 'Лайки',
    appointments: 'Записи',
    view: 'посмотреть',
    ok: 'OK',
    cancel: 'Отменить',
    wantToCancelAppointment: 'Вы уверены, что хотите отменить запись?',
    yes: 'Да',
    no: 'Нет',
    changeProfilePics: 'Изменить фото профиля',
    personalDetails: 'Персональные данные',
    specialistDetails: 'Детали специалиста',
    appSettings: 'Настройки приложения',
    language: 'Язык',
    notifications: 'Уведомления',
    profession: 'Профессия',
    yearsOfExperience: 'Лет опыта',
    serviceCategory: 'Категория услуг',
    bio: 'Биография',
    previousWork: 'Предыдущие работы',
    edit: 'Редактировать',
    uploadImages: 'Загрузить изображения',
    note: 'Заметка',
    phoneNumber: 'Номер телефона',
    serviceProvide: 'Услуги, которые вы предоставляете',
    review: 'Отзывы',
    callMe: 'Позвоните мне',
    reviews: 'Отзывы',
    leaveA: 'Оставьте отзыв',
    howDidItGo: 'Как все прошло?',
    takeAMomentToRate: 'Возьмите момент, чтобы оценить',
    writeYourRevHere: 'Напишите свой отзыв здесь',
    yourAddress: "Укажите свой домашний адрес в Настройках для удобного планирования в будущем. Включите геолокацию, чтобы показать стилистов в вашем городе.",
    city: 'Город',
    pickService: 'Выберите категории услуг, чтобы привлечь клиентов, ищущих ваши услуги.',
    selectedCategory: 'Выбранная категория',
    selectedService: 'Выбранные вами услуги будут отображаться на вашей странице профиля, чтобы привлекать клиентов.',
    services: 'Услуги',
    priceRange: 'Диапазон цен',
    price: 'Цена',
    accept: 'Принять',
    serviceName: 'Название услуги',
    goToClient: 'Готов к клиенту',
    save: 'Сохранить',
    create: 'Создать',
    update: 'Обновить',
    youCanUploadMore: 'Вы можете загрузить ещё',
    goBack: 'Назад',
    address: 'Адрес',
    availableTimeSlots: 'Доступные временные слоты',
    addressOfMeeting: 'Адрес встречи',
    yurAddress: 'Ваш адрес',
    specialistAddress: 'Адрес специалиста',
    makeAppointment: 'Записаться',
    goToAdmin: 'Перейти в админку',
    admin: 'Администратор',
    loginAsAdmin: 'Вход как администратор',
    loginFailed: 'Вход не удался',
    name: 'Имя',
    enterName: 'Введите имя',
    nameRequired: 'Имя обязательно',
    nameInvalid: 'Неверное имя',
    totalUsers: 'Всего пользователей',
    help: 'Помощь',
    subject: 'Тема',
    message: 'Сообщение',
    submit: 'Отправить',
    specialistNotReady: 'Специалист не готов приехать по вашему адресу',
  };
}
