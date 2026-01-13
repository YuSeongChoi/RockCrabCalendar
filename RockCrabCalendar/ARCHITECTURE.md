## Clean Architecture Overview

This project is organized around a simple Clean Architecture flow.

```
View (SwiftUI)
  -> ViewModel (@Observable)
    -> UseCase (Domain)
      -> Repository (Protocol)
        -> DataSource (Firestore / UserDefaults / HTTP)
```

### QWER Schedule Flow
```
HomeMainView
  -> QWERScheduleViewModel
    -> QWERScheduleUseCase
      -> QWERScheduleRepository (protocol)
        -> QWERScheduleService (Firestore + UserDefaults)
```

### User Schedule Flow
```
HomeMainView
  -> UserScheduleViewModel
    -> UserScheduleUseCase
      -> UserScheduleRepository (protocol)
        -> UserScheduleService (UserDefaults)
```

### YouTube Flow
```
YouTubeListView
  -> YouTubeListViewModel
    -> YouTubeRepository (protocol)
      -> YouTubeRepositoryImpl (YouTubeAPIClient)
```

### Holiday Flow
```
CalendarViewModel
  -> HolidayUseCase
    -> HolidayRepositoryProtocol (protocol)
      -> HolidayRepository (HolidayAPIClient + Cache)
```

### Domain Model Boundary
```
DTO (Network/Storage)
  -> Repository maps to Domain models (e.g. HolidayInfo, YouTubeVideo)
  -> UseCase returns Domain models to ViewModel
```

### Dependency Assembly
```
RockCrabCalendarApp
  -> AppEnvironment (DI container)
    -> UseCases wired to concrete repositories
```
