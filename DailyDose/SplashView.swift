import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var store: AppStore
    @State private var animateIcon = false
    @State private var goNext = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.85), Color.teal.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.16))
                        .frame(width: 148, height: 148)

                    Image(systemName: "pills.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white)
                        .scaleEffect(animateIcon ? 1.05 : 0.92)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: animateIcon)
                }

                Text("DailyDose")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Track medications, reminders, and daily progress")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding()
        }
        .task {
            animateIcon = true
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            goNext = true
        }
        .fullScreenCover(isPresented: $goNext) {
            ContentView()
                .environmentObject(store)
        }
    }
}
