import SwiftUI

struct ProfileView: View {
    @AppStorage("name") private var name: String = ""
    @AppStorage("email") private var email: String = ""
    @AppStorage("gender") private var gender: String = ""
    @AppStorage("weight") private var weight: String = ""
    @AppStorage("dob") private var dob: Date = Date()

    @State private var isEditing = false // Start in view-only mode
    @State private var showValidationError = false
    @State private var validationMessage = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section(header: Text("Personal Info")) {
                if isEditing {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Gender", text: $gender)
                } else {
                    ProfileRow(label: "Name", value: name)
                    ProfileRow(label: "Email", value: email)
                    ProfileRow(label: "Gender", value: gender)
                }
            }

            Section(header: Text("Health Info")) {
                if isEditing {
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.decimalPad)
                    DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                } else {
                    ProfileRow(label: "Weight", value: (Double(weight) != nil ? "\(weight) lbs" : "—"))
                    ProfileRow(label: "Date of Birth", value: formattedDate(dob))
                }
            }

            if showValidationError {
                Text(validationMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Section {
                Button(isEditing ? "Save Profile" : "Edit Profile") {
                    if isEditing {
                        if validateProfile() {
                            isEditing = false
                            showValidationError = false
                        } else {
                            showValidationError = true
                        }
                    } else {
                        isEditing = true
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }

            // 🔴 Delete Profile Section
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete Profile")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Profile")
        .alert("Are you sure you want to delete your profile?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteProfile()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func validateProfile() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Name cannot be empty."
            return false
        }

        if !isValidEmail(email) {
            validationMessage = "Invalid email format."
            return false
        }

        if Double(weight) == nil || (Double(weight) ?? 0) <= 0 {
            validationMessage = "Weight must be a positive number."
            return false
        }

        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func deleteProfile() {
        name = ""
        email = ""
        gender = ""
        weight = ""
        dob = Date()
        isEditing = false // Reset to view-only mode after deleting
    }
}

struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .foregroundColor(.primary)
        }
    }
}
