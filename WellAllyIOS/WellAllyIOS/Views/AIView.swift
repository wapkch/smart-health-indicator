import SwiftUI

struct AIView: View {
    @Environment(AISettingsStore.self) private var settings

    let store: DemoHealthDataStore

    @State private var question = String(localized: "ai.default_question")
    @State private var answer: HealthAgentAnswer?
    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HealthCard {
                        StatusPill(text: "ai.status.safety_bounded", tint: WellAllyColor.warning, background: WellAllyColor.warningSoft)
                        Text("ai.ask.title")
                            .font(.title2.bold())
                        Text("ai.ask.subtitle")
                            .foregroundStyle(WellAllyColor.secondaryText)

                        TextField("ai.question.placeholder", text: $question, axis: .vertical)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            Task { await runDemoAgent() }
                        } label: {
                            if isRunning {
                                ProgressView()
                            } else {
                                Label("ai.run_demo", systemImage: "sparkles")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(WellAllyColor.primary)
                        .disabled(isRunning)
                    }

                    if let answer {
                        HealthCard {
                            Text(answer.summary)
                                .font(.headline)
                            Text(LocalizedStringKey(answer.safetyBoundary))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(WellAllyColor.risk)

                            Text("ai.evidence.title")
                                .font(.subheadline.bold())
                                .padding(.top, 4)
                            ForEach(answer.evidence, id: \.self) { item in
                                Text(LocalizedStringKey(item))
                                    .font(.caption)
                                    .foregroundStyle(WellAllyColor.secondaryText)
                            }

                            Text("ai.next_actions.title")
                                .font(.subheadline.bold())
                                .padding(.top, 4)
                            ForEach(answer.suggestedNextActions, id: \.self) { action in
                                Label(LocalizedStringKey(action), systemImage: "checkmark.circle")
                                    .font(.caption)
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(WellAllyColor.risk)
                    }
                }
                .padding(20)
            }
            .background(WellAllyColor.background)
            .navigationTitle("ai.title")
            .toolbar {
                Button {
                    showsSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("ai.settings.accessibility")
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
            }
        }
    }

    private func runDemoAgent() async {
        isRunning = true
        errorMessage = nil
        defer { isRunning = false }

        do {
            settings.saveConfig()
            let loop = AgentLoop(
                client: DemoLLMClient(),
                config: settings.config,
                tools: HealthToolRegistry(store: store)
            )
            answer = try await loop.answer(question: question)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
