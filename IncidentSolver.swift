import SwiftUI
import MapKit
import Combine

// MARK: - Models
enum IncidentStatus: String, CaseIterable, Identifiable {
    case stopped, delayed, caution, normal
    var id: String { rawValue }

    var label: String {
        switch self {
        case .stopped: return "停止"
        case .delayed: return "遅延"
        case .caution: return "注意"
        case .normal: return "平常"
        }
    }

    var color: Color {
        switch self {
        case .stopped: return .red
        case .delayed: return .orange
        case .caution: return .yellow
        case .normal: return .green
        }
    }
}

enum UserIntent: String, CaseIterable, Identifiable {
    case hurry, detour, killTime
    var id: String { rawValue }

    var label: String {
        switch self {
        case .hurry: return "急いでいる"
        case .detour: return "迂回したい"
        case .killTime: return "時間を潰せる"
        }
    }
}

enum RecommendationAction: Identifiable {
    case map
    case fact
    case externalURL(String)

    var id: String {
        switch self {
        case .map: return "map"
        case .fact: return "fact"
        case .externalURL(let url): return "external_\(url)"
        }
    }
}

enum DisplayScenario: String, CaseIterable, Identifiable {
    case normal, delayHeavy, stoppedHeavy
    var id: String { rawValue }

    var label: String {
        switch self {
        case .normal: return "通常"
        case .delayHeavy: return "遅延多め"
        case .stoppedHeavy: return "停止多め"
        }
    }
}

struct Line: Identifiable {
    let id: UUID
    let name: String
}

struct Station: Identifiable {
    let id: UUID
    let name: String
    let lat: Double
    let lon: Double
}

struct Incident: Identifiable {
    let id: UUID
    let status: IncidentStatus
    let lineId: UUID?
    let affectedText: String
    let relatedStationIds: [UUID]
    let summary: String
    let startedAt: Date
    let sourceURL: String?
}

struct Recommendation: Identifiable {
    let id: UUID
    let intent: UserIntent
    let title: String
    let detail: String
    let actionKind: [RecommendationAction]
}

// MARK: - Mock Data
struct MockData {
    static let lines: [Line] = [
        Line(id: UUID(), name: "北部快速線"),
        Line(id: UUID(), name: "南海本線"),
        Line(id: UUID(), name: "中央メトロ"),
        Line(id: UUID(), name: "湾岸ライナー"),
        Line(id: UUID(), name: "空港アクセス"),
        Line(id: UUID(), name: "谷間ローカル"),
    ]

    static let stations: [Station] = [
        Station(id: UUID(), name: "北浜", lat: 35.68, lon: 139.77),
        Station(id: UUID(), name: "南浜", lat: 35.64, lon: 139.74),
        Station(id: UUID(), name: "中央", lat: 35.69, lon: 139.70),
        Station(id: UUID(), name: "桜川", lat: 35.67, lon: 139.73),
        Station(id: UUID(), name: "柳橋", lat: 35.65, lon: 139.76),
        Station(id: UUID(), name: "港前", lat: 35.63, lon: 139.78),
        Station(id: UUID(), name: "空港口", lat: 35.62, lon: 139.82),
        Station(id: UUID(), name: "東端", lat: 35.69, lon: 139.83),
        Station(id: UUID(), name: "西ヶ丘", lat: 35.70, lon: 139.68),
        Station(id: UUID(), name: "谷間", lat: 35.71, lon: 139.65)
    ]

    static func normalIncidents(base: Date) -> [Incident] {
        return [
            Incident(
                id: UUID(),
                status: .stopped,
                lineId: lines[0].id,
                affectedText: "北浜〜桜川で運転見合わせ",
                relatedStationIds: [stations[0].id, stations[3].id],
                summary: "車両点検のため、北部快速線が一部区間で停止中です。",
                startedAt: base.addingTimeInterval(-5 * 60),
                sourceURL: "https://example.com/stop"
            ),
            Incident(
                id: UUID(),
                status: .delayed,
                lineId: lines[2].id,
                affectedText: "中央〜港前で10-15分遅れ",
                relatedStationIds: [stations[2].id, stations[5].id],
                summary: "駅構内安全確認の影響で遅延が発生しています。",
                startedAt: base.addingTimeInterval(-40 * 60),
                sourceURL: "https://example.com/delay"
            ),
            Incident(
                id: UUID(),
                status: .caution,
                lineId: lines[4].id,
                affectedText: "強風のため減速運転",
                relatedStationIds: [stations[6].id, stations[7].id],
                summary: "空港アクセス線で強風により速度を落として運転中です。",
                startedAt: base.addingTimeInterval(-2 * 3600),
                sourceURL: nil
            )
        ]
    }

    static func delayHeavyIncidents(base: Date) -> [Incident] {
        return [
            Incident(
                id: UUID(),
                status: .delayed,
                lineId: lines[1].id,
                affectedText: "南浜〜港前で15-25分遅れ",
                relatedStationIds: [stations[1].id, stations[5].id],
                summary: "信号点検の影響で遅延が拡大しています。",
                startedAt: base.addingTimeInterval(-70 * 60),
                sourceURL: "https://example.com/delay-heavy"
            ),
            Incident(
                id: UUID(),
                status: .delayed,
                lineId: lines[3].id,
                affectedText: "湾岸ライナー全線で10分前後の遅れ",
                relatedStationIds: [stations[5].id, stations[7].id],
                summary: "前列車混雑の影響で遅延が発生しています。",
                startedAt: base.addingTimeInterval(-25 * 60),
                sourceURL: nil
            ),
            Incident(
                id: UUID(),
                status: .caution,
                lineId: lines[5].id,
                affectedText: "谷間ローカル線で間引き運転",
                relatedStationIds: [stations[9].id],
                summary: "車両不足のため一部列車を運休しています。",
                startedAt: base.addingTimeInterval(-110 * 60),
                sourceURL: "https://example.com/caution"
            )
        ]
    }

    static func stoppedHeavyIncidents(base: Date) -> [Incident] {
        return [
            Incident(
                id: UUID(),
                status: .stopped,
                lineId: lines[0].id,
                affectedText: "北浜〜中央で運転見合わせ",
                relatedStationIds: [stations[0].id, stations[2].id],
                summary: "人身事故のため、上下線とも停止しています。",
                startedAt: base.addingTimeInterval(-15 * 60),
                sourceURL: "https://example.com/stop-heavy"
            ),
            Incident(
                id: UUID(),
                status: .stopped,
                lineId: lines[4].id,
                affectedText: "空港アクセス線 全線運休",
                relatedStationIds: [stations[6].id, stations[7].id],
                summary: "強風警報のため終日運休の可能性があります。",
                startedAt: base.addingTimeInterval(-3 * 3600),
                sourceURL: nil
            ),
            Incident(
                id: UUID(),
                status: .delayed,
                lineId: lines[2].id,
                affectedText: "中央メトロで15分遅れ",
                relatedStationIds: [stations[2].id],
                summary: "混雑による折返し調整を実施中です。",
                startedAt: base.addingTimeInterval(-55 * 60),
                sourceURL: "https://example.com/metro"
            )
        ]
    }

    static let recommendations: [Recommendation] = [
        Recommendation(
            id: UUID(),
            intent: .hurry,
            title: "タクシーに切り替え",
            detail: "北浜駅前でタクシー乗り場利用可。10-15分短縮。",
            actionKind: [.externalURL("https://example.com/taxi"), .map, .fact]
        ),
        Recommendation(
            id: UUID(),
            intent: .hurry,
            title: "中央メトロへ乗り換え",
            detail: "中央メトロは遅延あるものの動いています。",
            actionKind: [.map, .fact]
        ),
        Recommendation(
            id: UUID(),
            intent: .detour,
            title: "湾岸ライナー経由に変更",
            detail: "所要+20分だが運転継続中。座れる可能性高。",
            actionKind: [.map, .externalURL("https://example.com/route")]
        ),
        Recommendation(
            id: UUID(),
            intent: .detour,
            title: "バス振替案内を確認",
            detail: "南浜から港前行きバスが10分間隔で運行。",
            actionKind: [.externalURL("https://example.com/bus"), .fact]
        ),
        Recommendation(
            id: UUID(),
            intent: .killTime,
            title: "駅ナカカフェで待機",
            detail: "桜川駅改札内にカフェあり。Wi-Fi利用可。",
            actionKind: [.externalURL("https://example.com/cafe")]
        ),
        Recommendation(
            id: UUID(),
            intent: .killTime,
            title: "空港アクセス再開を待つ",
            detail: "再開見込みは未定。30分おきに状況確認を。",
            actionKind: [.fact]
        )
    ]
}

// MARK: - App Store
final class AppStore: ObservableObject {
    @Published var selectedStationId: UUID?
    @Published var selectedLineId: UUID?
    @Published var selectedIncidentId: UUID?
    @Published var selectedIntent: UserIntent = .hurry
    @Published var now: Date = Date()
    @Published var scenario: DisplayScenario = .normal

    private let normalIncidents: [Incident]
    private let delayHeavyIncidents: [Incident]
    private let stoppedHeavyIncidents: [Incident]
    private var timerCancellable: AnyCancellable?

    init() {
        let base = Date()
        self.normalIncidents = MockData.normalIncidents(base: base)
        self.delayHeavyIncidents = MockData.delayHeavyIncidents(base: base)
        self.stoppedHeavyIncidents = MockData.stoppedHeavyIncidents(base: base)
        startTimer()
    }

    var incidents: [Incident] {
        switch scenario {
        case .normal: return normalIncidents
        case .delayHeavy: return delayHeavyIncidents
        case .stoppedHeavy: return stoppedHeavyIncidents
        }
    }

    var selectedStation: Station? {
        guard let id = selectedStationId else { return nil }
        return MockData.stations.first { $0.id == id }
    }

    var selectedLine: Line? {
        guard let id = selectedLineId else { return nil }
        return MockData.lines.first { $0.id == id }
    }

    var selectedIncident: Incident? {
        if let id = selectedIncidentId {
            return incidents.first { $0.id == id }
        }
        return incidents.first
    }

    func selectIncident(_ incident: Incident) {
        selectedIncidentId = incident.id
        selectedLineId = incident.lineId
        selectedStationId = incident.relatedStationIds.first
    }

    private func startTimer() {
        let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
        timerCancellable = timer.sink { [weak self] _ in
            self?.now = Date()
        }
    }
}

// MARK: - App Entry
@main
struct IncidentSolverApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

// MARK: - Content
struct ContentView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "exclamationmark.triangle")
            }

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationStack {
                MapContainerView()
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

// MARK: - Views
struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedIncidentForNavigation: Incident?
    @State private var showFactFromCard = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if store.incidents.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(store.incidents) { incident in
                            IncidentCardView(incident: incident)
                                .onTapGesture {
                                    store.selectIncident(incident)
                                    selectedIncidentForNavigation = incident
                                    showFactFromCard = true
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Home")
        .navigationDestination(isPresented: $showFactFromCard) {
            if let incident = selectedIncidentForNavigation {
                FactView(incident: incident)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("選択中の駅")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(store.selectedStation?.name ?? "未設定")
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.thinMaterial)
                .cornerRadius(12)
            if let line = store.selectedLine {
                Text("路線: \(line.name)")
                    .font(.subheadline)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.largeTitle)
            Text("現在、表示する障害情報はありません")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}

struct FactView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.openURL) private var openURL

    var incident: Incident?

    var body: some View {
        let target = incident ?? store.selectedIncident
        VStack(alignment: .leading, spacing: 16) {
            if let incident = target {
                statusSection(incident)
                Text(incident.summary)
                    .font(.body)
                if let urlString = incident.sourceURL, let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "link")
                            Text("参照元を開く")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            } else {
                Text("対象の障害が見つかりません")
                    .foregroundStyle(.secondary)
            }

            NavigationLink {
                ActionView()
            } label: {
                Text("どうする？")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .navigationTitle("Fact")
    }

    private func statusSection(_ incident: Incident) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                StatusBadgeView(status: incident.status)
                Text(lineName(for: incident))
                    .font(.headline)
                Spacer()
            }
            Text(incident.affectedText)
                .font(.subheadline)
            ElapsedTimeText(startedAt: incident.startedAt, now: store.now)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func lineName(for incident: Incident) -> String {
        guard let id = incident.lineId, let line = MockData.lines.first(where: { $0.id == id }) else {
            return "路線不明"
        }
        return line.name
    }
}

struct ActionView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.openURL) private var openURL

    private var filteredRecommendations: [Recommendation] {
        MockData.recommendations.filter { $0.intent == store.selectedIntent }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("目的に合わせた行動を選びましょう")
                .font(.headline)
            IntentPickerView(selectedIntent: $store.selectedIntent)
            if filteredRecommendations.isEmpty {
                Text("現在表示できる提案がありません")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredRecommendations) { rec in
                            RecommendationCardView(recommendation: rec) { action in
                                handle(action: action)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Action")
    }

    private func handle(action: RecommendationAction) {
        switch action {
        case .map:
            // Navigation handled by link inside card
            break
        case .fact:
            break
        case .externalURL(let value):
            if let url = URL(string: value) {
                openURL(url)
            }
        }
    }
}

struct SearchView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query: String = ""

    private var filteredStations: [Station] {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return MockData.stations
        }
        return MockData.stations.filter { station in
            station.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("駅を検索", text: $query)
                .textFieldStyle(.roundedBorder)

            List(filteredStations) { station in
                NavigationLink {
                    FactView(incident: store.selectedIncident)
                } label: {
                    Text(station.name)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    store.selectedStationId = station.id
                })
            }
            .listStyle(.plain)
        }
        .padding()
        .navigationTitle("Search")
    }
}

struct MapContainerView: View {
    @EnvironmentObject private var store: AppStore

    private var annotations: [Station] {
        guard let incident = store.selectedIncident else { return [] }
        return MockData.stations.filter { incident.relatedStationIds.contains($0.id) }
    }

    var body: some View {
        Map(initialPosition: .region(defaultRegion)) {
            ForEach(annotations) { station in
                Annotation(station.name, coordinate: CLLocationCoordinate2D(latitude: station.lat, longitude: station.lon))
            }
        }
        .navigationTitle("Map")
    }

    private var defaultRegion: MKCoordinateRegion {
        if let first = annotations.first {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: first.lat, longitude: first.lon), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        }
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.68, longitude: 139.76), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Form {
            Section("表示シナリオ") {
                Picker("シナリオ", selection: $store.scenario) {
                    ForEach(DisplayScenario.allCases) { scenario in
                        Text(scenario.label).tag(scenario)
                    }
                }
                .pickerStyle(.segmented)
                Text("デモ用に障害件数を切り替えます")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Tips") {
                Text("ダークモードでも視認性を確認してください。")
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Components
struct StatusBadgeView: View {
    let status: IncidentStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.bold))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(8)
    }
}

struct ElapsedTimeText: View {
    let startedAt: Date
    let now: Date

    var body: some View {
        Text(elapsedText(startedAt: startedAt, now: now))
    }

    private func elapsedText(startedAt: Date, now: Date) -> String {
        let diff = Int(now.timeIntervalSince(startedAt) / 60)
        let hours = diff / 60
        let minutes = diff % 60
        if hours == 0 {
            return "発生から\(minutes)分経過"
        } else {
            return "発生から\(hours)時間\(minutes)分経過"
        }
    }
}

struct IncidentCardView: View {
    @EnvironmentObject private var store: AppStore
    let incident: Incident

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                StatusBadgeView(status: incident.status)
                VStack(alignment: .leading, spacing: 4) {
                    Text(lineName)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(incident.affectedText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
            ElapsedTimeText(startedAt: incident.startedAt, now: store.now)
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                NavigationLink {
                    store.selectIncident(incident)
                    FactView(incident: incident)
                } label: {
                    Text("事実を見る")
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                NavigationLink {
                    store.selectIncident(incident)
                    ActionView()
                } label: {
                    Text("どうする？")
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private var lineName: String {
        if let lineId = incident.lineId, let line = MockData.lines.first(where: { $0.id == lineId }) {
            return line.name
        }
        return "路線不明"
    }
}

struct RecommendationCardView: View {
    @EnvironmentObject private var store: AppStore
    let recommendation: Recommendation
    var onAction: (RecommendationAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recommendation.title)
                .font(.headline)
            Text(recommendation.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                ForEach(recommendation.actionKind) { action in
                    switch action {
                    case .map:
                        NavigationLink {
                            MapContainerView()
                        } label: {
                            actionLabel("地図を見る")
                        }
                    case .fact:
                        NavigationLink {
                            FactView(incident: store.selectedIncident)
                        } label: {
                            actionLabel("事実を見る")
                        }
                    case .externalURL:
                        Button {
                            onAction(action)
                        } label: {
                            actionLabel("外部を開く")
                        }
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private func actionLabel(_ text: String) -> some View {
        Text(text)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
    }
}

struct IntentPickerView: View {
    @Binding var selectedIntent: UserIntent

    var body: some View {
        Picker("意図", selection: $selectedIntent) {
            ForEach(UserIntent.allCases) { intent in
                Text(intent.label).tag(intent)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(AppStore())
}
