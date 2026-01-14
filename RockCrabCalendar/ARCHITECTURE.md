## Clean Architecture Overview

This project is organized around a simple Clean Architecture flow.

```
View (SwiftUI)
  -> ViewModel (@Observable)
    -> UseCase (Domain)
      -> Repository (Protocol)
        -> DataSource (Firestore / UserDefaults / HTTP)
```

### Presentation Layer Structure
```
RockCrabCalendar/Presentation
  - App (AppDelegate / AppEnvironment / App entry)
  - Features (Views / ViewModels)
  - Core (App-level services)
  - Utils (UI/helpers used by Presentation)
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
    -> YouTubeUseCase
      -> YouTubeRepository (protocol)
        -> YouTubeRepositoryImpl (YouTubeAPIClient)
```

### Holiday Flow
```
CalendarViewModel
  -> HolidayUseCase
    -> HolidayRepositoryProtocol (protocol)
      -> HolidayRepository (HolidayAPIClient + Cache)
  -> HolidayStore (cache-backed, for UI lookup)
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
  -> AppEnvironment.live() (composition root)
    -> DataSources -> Repositories -> UseCases
```

### SPM Module (First Step)
```
RockCrabShared (local package)
  - AppDateFormats / AppStorageKeys / HolidayInfo
```

### SPM Module (Domain)
```
RockCrabDomain (local package)
  - UseCases / Repository protocols / Domain models
```
