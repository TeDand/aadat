# aadat

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Decisions 

### MVVM architecture

This project uses the Model-View-ViewModel (MVVM) architecture, as recommended by Flutter. 

MVVM is a software architecture pattern used in app development to separate concerns — meaning it keeps your code organized by dividing it into 3 layers:
1. Model → Handles the data and business logic.
2. View → The UI (what the user sees and interacts with).
3. ViewModel → The bridge between Model and View, holding the app’s state and exposing data in a way the View can easily use.

#### Model 

- Data and rules 
- Responsible for fetching, storing, and processing data.
- It doesn't have any information about the UI 

#### View 

- The UI 
- Shows information to the users, and captures user input 
- It doesn't contain any logic, just displays what it receives from the ViewModel.

#### ViewModel 

- The middle man, and the state holder 
- Knows about the Model and transforms its raw data into something the View can use 
- Exposes data as _observables_ so that UI can update automatically when the data changes 
- Handles user actions by calling the Model 


### Database 

// TODO 


### App Layout and design 

// In progress 

### Stretch goals 

1. AI integration 
