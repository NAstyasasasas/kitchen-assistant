# Palate — Персональный кулинарный помощник 🍳

## 📌 О проекте
Palate — это мобильное приложение для любителей готовить. Помогает находить рецепты, вести кулинарный дневник, создавать свои рецепты и формировать список покупок.

## 🚀 Реализованный функционал (Дедлайн 2 - MVP)

### ✅ Готово:
- Регистрация и вход через Firebase Auth (с валидацией)
- Главный экран с лентой рецептов из TheMealDB
- Поиск рецептов по названию
- Фильтрация по кухням (Итальянская, Японская и др.)
- Фильтрация по типу блюда (Говядина, Курица, Паста, Десерты и др.)
- Детальный экран рецепта (ингредиенты, инструкция)
- Добавление рецепта в "Хочу приготовить" (Firestore)
- Экран профиля со статистикой (количество приготовленных и запланированных рецептов)
- Навигация через Coordinator + TabView

## 🧠 Архитектура

### 📱 iOS
- **Язык:** Swift 5+
- **Минимальная версия:** iOS 16
- **UI:** SwiftUI
- **Архитектура:** MVP + Coordinator
- **БД:** SwiftData (локально)
- **Бэкенд:** Firebase (Auth, Firestore, Storage)
- **API рецептов:** TheMealDB

### 🤖 Android
- **Язык:** Kotlin
- **Минимальная версия:** API 29 (Android 10)
- **UI:** Jetpack Compose
- **Архитектура:** Clean Architecture + MVVM
- **Сеть:** Retrofit
- **Асинхронность:** Coroutines + Flow
- **БД:** Room
- **DI:** Dagger Hilt
- **Бэкенд:** Firebase (Auth, Firestore, Storage)
- **API рецептов:** TheMealDB

## 🔌 API

### TheMealDB (бесплатное открытое API)
| Метод | Эндпоинт | Назначение |
|-------|----------|------------|
| GET | `/search.php?s={query}` | Поиск рецептов по названию |
| GET | `/filter.php?c={category}` | Фильтр по категории |
| GET | `/filter.php?a={area}` | Фильтр по кухне |
| GET | `/filter.php?i={ingredient}` | Фильтр по ингредиенту |
| GET | `/lookup.php?i={id}` | Полная информация о рецепте |

## 📂 Структура проекта (iOS)
| Папка | Назначение |
|-------|------------|
| `App/` | Точка входа: PalateApp.swift |
| `Coordinators/` | Навигация: AuthCoordinator, MainCoordinator |
| `Modules/Auth/` | Авторизация (Interactor, Presenter, View) |
| `Modules/Home/` | Главный экран с лентой рецептов |
| `Modules/Profile/` | Профиль и статистика пользователя |
| `Modules/RecipeDetail/` | Детальная информация о рецепте |
| `Modules/MyRecipes/` | Мои рецепты (в разработке) |
| `Modules/ShoppingList/` | Список покупок (в разработке) |
| `Modules/Plan/` | План питания (в разработке) |
| `Models/` | Модели данных (Recipe, UserRecipe, AuthModels) |
| `Services/` | Сервисы (API, Auth, Firebase) |
| `Common/` | Переиспользуемые UI компоненты |
| `Assets.xcassets/` | Ресурсы: картинки, шрифты, иконки |


## 🔗 Ссылки
- [Figma дизайн](https://www.figma.com/design/rXFhDYu5CotJj6NmKRnNXR/Palate)
- [iOS репозиторий](https://github.com/NAstyasasasas/kitchen-assistant)
- [Android репозиторий](https://github.com/yana-pv/app_palate.git)
- [Trello доска](https://trello.com/invite/b/69bd729e7bcb14dc04f6af09)

## 👥 Команда
- **iOS разработчик:** Анастасия ([@NAstyasasasas](https://github.com/NAstyasasasas))
- **Android разработчики:** Яна ([@yana-pv](https://github.com/yana-pv)), Галина ([@GalinaLi17](https://github.com/GalinaLi17))

## 📅 Статус
**Дедлайн 2 — MVP и базовая функциональность** ✅

- 5+ работающих экранов
- Интеграция с Firebase Auth
- Интеграция с TheMealDB API
- Feature parity между iOS и Android
- Git Flow (main, develop, feature/* ветки)
- 4 закрытых Pull Request'а
