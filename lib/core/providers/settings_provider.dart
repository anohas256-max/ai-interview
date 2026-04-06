import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark; 
  String currentLanguage = "English";

  final Map<String, Map<String, String>> _dictionary = {
    'English': {
      // Auth & Profile
      'login_title': 'Welcome Back', 
      'login_subtitle': 'Sign in to continue your training.', 
      'login': 'Login', 
      'email_hint': 'Email or Username', 
      'password_hint': 'Password', 
      'password_min': 'Password (min 6 chars)', 
      'confirm_pass': 'Confirm Password', 
      'sign_in_btn': 'Sign In', 
      'no_account': 'Don\'t have an account? Register', 
      'empty_login': 'Enter login', 
      'empty_pass': 'Enter password', 
      'empty_email': 'Enter email', 
      'short_login': 'Login is too short', 
      'taken_login': 'This username is taken 😔', 
      'invalid_email': 'Invalid email format', 
      'taken_email': 'Email already registered 😔', 
      'short_pass': 'Password must be at least 6 characters', 
      'pass_mismatch': 'Passwords do not match', 
      'register_title': 'Create Account', 
      'register_subtitle': 'Join and start your training.', 
      'register_btn': 'Register',
      'edit_name_title': 'Edit Display Name',
      'edit_name_hint': 'How should we call you?',
      'about_me_title': 'ABOUT ME / CONTEXT',
      'about_me_hint': 'Tell AI about your experience...',
      'lang_setting': 'Language',
      'pass_setting': 'Change Password',
      'notif_setting': 'Notifications',
      'support_setting': 'Help & Support',
      'dark_mode': 'Dark Mode',
      'sign_out': 'Sign Out',
      'cancel': 'Cancel',
      'save': 'Save',
      'update': 'Update',
      'loading': 'Loading...',
      'old_pass': 'Old Password',
      'new_pass': 'New Password',
      
      // Home Page
      'home_master': 'Master Your\n', 
      'home_interview': 'Interview', 
      'home_sub': 'AI-powered coaching tailored to\nyour specific role and goals.', 
      'continue_chat': 'Continue Chat', 
      'start_interview': 'Start Interview', 
      'free_sessions': '2 FREE SESSIONS REMAINING', 
      
      // Analysis Page
      'analysis_title': 'Session Analysis', 
      'error_server': 'Server Connection Error', 
      'error_gen': 'Failed to generate results.', 
      'retry_btn': 'Retry', 
      'overall_perf': 'OVERALL PERFORMANCE', 
      'avg_response': 'AVG. RESPONSE', 
      'total_time': 'TOTAL TIME', 
      'key_strengths': 'Key Strengths', 
      'areas_improve': 'Areas to Improve', 
      'work_mistakes': '📚 Work on Mistakes', 
      'read_this': 'What to read:', 
      'view_chat': 'View Full Chat', 
      'finish_exit': 'Finish & Exit',
      
      // Mode Selection
      'mode_title': 'Select Format',
      'mode_roleplay': 'Roleplay Interview',
      'mode_roleplay_desc': 'Full immersion. HR manager, resume questions, roleplay, and soft skills check.',
      'mode_quiz': 'Knowledge Check',
      'mode_quiz_desc': 'Strict focus on hard skills and theory. No fluff, only topic-specific questions and evaluation.',

      // Setup Page (Roleplay)
      'setup_title': 'Interview Setup',
      'desired_role': 'DESIRED ROLE',
      'interviewer_type': 'INTERVIEWER TYPE',
      'difficulty_level': 'DIFFICULTY LEVEL',
      'work_modes': 'WORK MODES',
      'intro_legend': 'Intro (Experience & Skills)',
      'teaching_mode': 'Teaching Mode 🎓 (Mistake Review)',
      'endless_mode': 'Endless Mode ♾️',
      'question_count': 'QUESTION COUNT',
      'custom_limit': 'Custom ⚙️',
      'custom_limit_hint': 'Enter number (max 1000)',
      'comm_format': 'COMMUNICATION STYLE',
      'start_btn': 'Start Interview',
      'custom_opt': 'Custom ✍️',
      'custom_role_hint': 'E.g., Senior Dart Developer',
      'custom_persona_hint': 'E.g., Angry CEO',

      // Setup Quiz
      'setup_quiz_title': 'Quiz Setup',
      'quiz_topic': 'QUIZ TOPIC / PROFESSION',
      'quiz_duration': 'QUIZ DURATION',
      'start_quiz_btn': 'Start Knowledge Check',
      'custom_topic_hint': 'E.g., Quantum Physics',

      // Chat & Transcript Page
      'live': 'Live',
      'end': 'END',
      'ai_typing': 'AI is typing...',
      'your_answer': 'Your answer...',
      'legend_hint': 'Briefly introduce yourself...',
      'fluff_warn': 'Too much fluff. Be specific.',
      'retry_send': 'Retry sending',
      'interview_aborted': 'Interview aborted. View results',
      'session_finished': 'Session complete! View results',
      'transcript_title': 'Transcript',
      'no_rating': 'No rating received',

      // Dropdowns & Snackbars
      'persona_hr': 'Strict HR Manager', 'persona_recruiter': 'Friendly Recruiter', 
      'persona_techlead': 'Picky Tech Lead', 'persona_fool': 'Clueless Interviewer',
      'diff_junior': 'Junior (Basic)', 'diff_middle': 'Middle (Standard)', 
      'diff_senior': 'Senior (Hardcore)', 'diff_progressive': 'Progressive (Adaptive)',
      'quiz_short': 'Short (3-5 questions)', 'quiz_medium': 'Medium (8-10 questions)', 'quiz_long': 'Long (14-16 questions)',
      'style_friendly': 'Friendly', 'style_friendly_desc': 'Soft and supportive',
      'style_strict': 'To the point', 'style_strict_desc': 'Dry, clear, no emotions',
      'style_stress': 'Stress-test', 'style_stress_desc': 'Pressures and rushes you',
      'style_pedant': 'Nitpicker', 'style_pedant_desc': 'Finds fault with every detail',
      'style_provocateur': 'Provocateur', 'style_provocateur_desc': 'Tries to confuse and mislead',
      'snack_name_updated': 'Name updated successfully!', 
      'snack_server_error': 'Server error. Try again later.', 
      'snack_pass_updated': 'Password updated successfully!', 
      'snack_coming_soon': 'Feature coming soon!',
      
      // History Drawer
      'drawer_archive': 'Session Archive', 'drawer_empty': 'No saved sessions yet.', 
      'drawer_score': 'Score', 'just_now': 'JUST NOW', 'yesterday': 'YESTERDAY', 
      'h_ago': 'H AGO', 'm_ago': 'M AGO',
    },
    'Русский': {
      // Auth & Profile
      'login_title': 'С возвращением', 
      'login_subtitle': 'Войдите, чтобы продолжить тренировки.', 
      'login': 'Логин', 
      'email_hint': 'Email', 
      'password_hint': 'Пароль', 
      'password_min': 'Пароль (минимум 6 символов)', 
      'confirm_pass': 'Подтвердите пароль', 
      'sign_in_btn': 'Войти', 
      'no_account': 'Нет аккаунта? Зарегистрироваться', 
      'empty_login': 'Введите логин', 
      'empty_pass': 'Введите пароль', 
      'empty_email': 'Введите email', 
      'short_login': 'Логин слишком короткий', 
      'taken_login': 'Это имя уже занято 😔', 
      'invalid_email': 'Некорректный формат почты', 
      'taken_email': 'На этот email уже создан акк 😔', 
      'short_pass': 'Пароль должен быть не менее 6 символов', 
      'pass_mismatch': 'Пароли не совпадают', 
      'register_title': 'Регистрация', 
      'register_subtitle': 'Присоединяйтесь и начните тренировки.', 
      'register_btn': 'Зарегистрироваться',
      'edit_name_title': 'Изменить имя',
      'edit_name_hint': 'Как нам вас называть?',
      'about_me_title': 'ОБО МНЕ / КОНТЕКСТ',
      'about_me_hint': 'Расскажите ИИ о своем опыте...',
      'lang_setting': 'Язык',
      'pass_setting': 'Сменить пароль',
      'notif_setting': 'Уведомления',
      'support_setting': 'Поддержка',
      'dark_mode': 'Темная тема',
      'sign_out': 'Выйти',
      'cancel': 'Отмена',
      'save': 'Сохранить',
      'update': 'Обновить',
      'loading': 'Загрузка...',
      'old_pass': 'Текущий пароль',
      'new_pass': 'Новый пароль',
      
      // Home Page
      'home_master': 'Прокачай свое\n', 
      'home_interview': 'Интервью', 
      'home_sub': 'ИИ-коучинг, адаптированный под\nтвою роль и цели.', 
      'continue_chat': 'Продолжить чат', 
      'start_interview': 'Начать интервью', 
      'free_sessions': 'ОСТАЛОСЬ 2 БЕСПЛАТНЫЕ СЕССИИ', 
      
      // Analysis Page
      'analysis_title': 'Анализ сессии', 
      'error_server': 'Ошибка связи с сервером', 
      'error_gen': 'Не удалось сгенерировать итоги.', 
      'retry_btn': 'Повторить попытку', 
      'overall_perf': 'ОБЩИЙ РЕЗУЛЬТАТ', 
      'avg_response': 'СРЕДНЕЕ ВРЕМЯ', 
      'total_time': 'ОБЩЕЕ ВРЕМЯ', 
      'key_strengths': 'Сильные стороны', 
      'areas_improve': 'Зоны для роста', 
      'work_mistakes': '📚 Работа над ошибками', 
      'read_this': 'Что почитать:', 
      'view_chat': 'Смотреть весь чат', 
      'finish_exit': 'Завершить и выйти',

      // Mode Selection
      'mode_title': 'Выбор формата',
      'mode_roleplay': 'Сюжетное собеседование',
      'mode_roleplay_desc': 'Полное погружение в роль. HR-менеджер, вопросы по резюме, отыгрыш ситуаций и проверка софт-скиллов.',
      'mode_quiz': 'Проверка знаний',
      'mode_quiz_desc': 'Строгий фокус на хард-скиллах и теории. Никакой воды, только вопросы по теме и оценка ответов.',

      // Setup Page (Roleplay)
      'setup_title': 'Настройка собеседования',
      'desired_role': 'ЖЕЛАЕМАЯ ДОЛЖНОСТЬ',
      'interviewer_type': 'ТИП ИНТЕРВЬЮЕРА',
      'difficulty_level': 'УРОВЕНЬ СЛОЖНОСТИ',
      'work_modes': 'РЕЖИМЫ РАБОТЫ',
      'intro_legend': 'Вводная часть (Опыт и скиллы)',
      'teaching_mode': 'Режим обучения 🎓 (Разбор ошибок)',
      'endless_mode': 'Бесконечный режим ♾️',
      'question_count': 'КОЛИЧЕСТВО ВОПРОСОВ',
      'custom_limit': 'Свой ⚙️',
      'custom_limit_hint': 'Введите кол-во (макс 1000)',
      'comm_format': 'ФОРМАТ ОБЩЕНИЯ',
      'start_btn': 'Начать собеседование',
      'custom_opt': 'Свой вариант ✍️',
      'custom_role_hint': 'Например: Капитан подводной лодки',
      'custom_persona_hint': 'Например: Кот, который умеет говорить',

      // Setup Quiz
      'setup_quiz_title': 'Настройка опроса',
      'quiz_topic': 'ТЕМА ОПРОСА / ПРОФЕССИЯ',
      'quiz_duration': 'ДЛИТЕЛЬНОСТЬ ОПРОСА',
      'start_quiz_btn': 'Начать проверку знаний',
      'custom_topic_hint': 'Например: Квантовая физика',

      // Chat & Transcript Page
      'live': 'Live',
      'end': 'END',
      'ai_typing': 'AI печатает...',
      'your_answer': 'Ваш ответ...',
      'legend_hint': 'Кратко расскажите о себе...',
      'fluff_warn': 'Слишком много воды. Отвечайте по сути.',
      'retry_send': 'Повторить отправку',
      'interview_aborted': 'Интервью прервано. Смотреть итоги',
      'session_finished': 'Сессия завершена! Смотреть итоги',
      'transcript_title': 'Разбор диалога',
      'no_rating': 'Оценка не получена',

      // Dropdowns & Snackbars
      'persona_hr': 'Строгий HR-менеджер', 'persona_recruiter': 'Добродушный рекрутер', 
      'persona_techlead': 'Придирчивый Техлид', 'persona_fool': 'Простофиля (вообще не шарит)',
      'diff_junior': 'Junior (Базовый)', 'diff_middle': 'Middle (Средний)', 
      'diff_senior': 'Senior (Хардкор)', 'diff_progressive': 'Progressive (Адаптивно)',
      'quiz_short': 'Мало (3-5 вопросов)', 'quiz_medium': 'Средне (8-10 вопросов)', 'quiz_long': 'Много (14-16 вопросов)',
      'style_friendly': 'Дружелюбный', 'style_friendly_desc': 'Мягко указывает на ошибки',
      'style_strict': 'По делу', 'style_strict_desc': 'Сухо, четко, без эмоций',
      'style_stress': 'Стресс-тест', 'style_stress_desc': 'Давит и торопит',
      'style_pedant': 'Душнила', 'style_pedant_desc': 'Придирается к каждой мелочи',
      'style_provocateur': 'Провокатор', 'style_provocateur_desc': 'Пытается запутать и сбить с толку',
      'snack_name_updated': 'Имя успешно обновлено!', 
      'snack_server_error': 'Ошибка сервера. Попробуйте позже.', 
      'snack_pass_updated': 'Пароль успешно изменен!', 
      'snack_coming_soon': 'Функция скоро появится!',
      
      // History Drawer
      'drawer_archive': 'Архив сессий', 'drawer_empty': 'Пока нет сохраненных сессий.', 
      'drawer_score': 'Оценка', 'just_now': 'ТОЛЬКО ЧТО', 'yesterday': 'ВЧЕРА', 
      'h_ago': 'Ч НАЗАД', 'm_ago': 'М НАЗАД',
    },
  };

  String t(String key) => _dictionary[currentLanguage]?[key] ?? key;

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (_dictionary.containsKey(lang)) {
      currentLanguage = lang;
      notifyListeners();
    }
  }
}