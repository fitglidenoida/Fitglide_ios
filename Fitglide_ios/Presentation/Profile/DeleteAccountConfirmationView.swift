import SwiftUI

struct DeleteAccountConfirmationView: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var showFinalConfirmation = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top, 40)
                
                // Title
                Text("Delete Account")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                // Warning Message
                VStack(spacing: 16) {
                    Text("This action cannot be undone!")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("Deleting your account will permanently remove:")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DeletionItem(icon: "heart.fill", text: "All health data and vitals")
                        DeletionItem(icon: "bed.double.fill", text: "Sleep tracking history")
                        DeletionItem(icon: "figure.run", text: "Workout logs and plans")
                        DeletionItem(icon: "fork.knife", text: "Meal and nutrition data")
                        DeletionItem(icon: "person.2.fill", text: "Social connections and challenges")
                        DeletionItem(icon: "chart.bar.fill", text: "Progress and achievements")
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showFinalConfirmation = true
                    }) {
                        Text("Delete My Account")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.medium)
                            .foregroundColor(colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(colors.primary.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(colors.background.ignoresSafeArea())
        }
        .alert("Final Confirmation", isPresented: $showFinalConfirmation) {
            Button("Delete Forever", role: .destructive) {
                onConfirm()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you absolutely sure? This will permanently delete your account and all associated data.")
        }
    }
}

struct DeletionItem: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.red)
                .frame(width: 24)
            
            Text(text)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.onSurface)
            
            Spacer()
        }
    }
} 