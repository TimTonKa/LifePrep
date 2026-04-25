import SwiftUI
import SwiftData
import MapKit

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct ShelterMapView: View {
    @StateObject private var vm: ShelterViewModel
    @State private var position: MapCameraPosition = .userLocation(fallback: .region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 23.7, longitude: 121.0),
                           latitudinalMeters: 400_000, longitudinalMeters: 400_000)
    ))

    init(context: ModelContext) {
        _vm = StateObject(wrappedValue: ShelterViewModel(context: context))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            map
            statusOverlay
        }
        .navigationTitle("附近避難所")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(item: $vm.selectedShelter) { shelter in
            ShelterDetailSheet(shelter: shelter, distance: vm.distance(to: shelter))
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("錯誤", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("確定") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onAppear {
            vm.requestLocation()
            if !vm.hasShelterData { vm.fetchShelters() }
        }
        .onChange(of: vm.userLocation) { _, loc in
            guard let loc else { return }
            withAnimation(.easeInOut(duration: 0.8)) {
                position = .region(MKCoordinateRegion(
                    center: loc,
                    latitudinalMeters: 3000,
                    longitudinalMeters: 3000
                ))
            }
        }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $position) {
            UserAnnotation()
            ForEach(vm.nearbyShelters) { shelter in
                Annotation(shelter.name, coordinate: shelter.coordinate, anchor: .bottom) {
                    ShelterPin(isSelected: vm.selectedShelter?.id == shelter.id)
                        .onTapGesture { vm.selectedShelter = shelter }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Overlays

    @ViewBuilder
    private var statusOverlay: some View {
        if vm.isLoading {
            floatingCard {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("正在下載避難所資料…").font(.subheadline)
                }
            }
        } else if !vm.hasShelterData {
            floatingCard {
                VStack(spacing: 10) {
                    Text("尚未下載避難所資料").font(.subheadline.bold())
                    Text("全台約 6,000 筆，建議在有網路時下載備用").font(.caption).foregroundStyle(.secondary)
                    Button("立即下載") { vm.fetchShelters() }
                        .buttonStyle(.borderedProminent).tint(.green)
                }
            }
        } else if vm.nearbyShelters.isEmpty && vm.userLocation != nil {
            floatingCard {
                Text("5 公里內無避難所資料").font(.subheadline).foregroundStyle(.secondary)
            }
        } else if vm.authStatus == .denied || vm.authStatus == .restricted {
            floatingCard {
                VStack(spacing: 6) {
                    Text("需要定位權限").font(.subheadline.bold())
                    Text("請至 設定 → 隱私權 → 定位服務 開啟").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func floatingCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(radius: 4)
            .padding(.horizontal)
            .padding(.bottom, 36)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { vm.fetchShelters() } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(vm.isLoading)
        }
    }
}

// MARK: - Shelter Pin

struct ShelterPin: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.orange : Color.green)
                .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                .shadow(radius: isSelected ? 4 : 2)
            Image(systemName: "house.fill")
                .font(.system(size: isSelected ? 16 : 12))
                .foregroundStyle(.white)
        }
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}

// MARK: - Detail Sheet

struct ShelterDetailSheet: View {
    let shelter: Shelter
    let distance: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("位置資訊") {
                    LabeledContent("名稱", value: shelter.name)
                    LabeledContent("地址", value: shelter.address)
                    LabeledContent("縣市", value: shelter.county)
                    if !distance.isEmpty {
                        LabeledContent("距離", value: distance)
                    }
                }

                Section("設施資訊") {
                    if shelter.capacity > 0 {
                        LabeledContent("容納人數", value: "\(shelter.capacity) 人")
                    }
                    if !shelter.disasterTypes.isEmpty {
                        LabeledContent("適用災害", value: shelter.disasterTypes)
                    }
                    facilityRow("室內空間", icon: "building.2", available: shelter.indoor)
                    facilityRow("室外空間", icon: "tree", available: shelter.outdoor)
                    if shelter.suitableForVulnerable {
                        Label("適合弱勢族群安置", systemImage: "figure.roll")
                            .foregroundStyle(.blue)
                    }
                }

                Section {
                    Button {
                        navigateTo(shelter)
                    } label: {
                        Label("導航前往", systemImage: "location.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())
                    .padding(.horizontal)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(shelter.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func facilityRow(_ label: String, icon: String, available: Bool) -> some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(available ? .green : .secondary)
        }
    }

    private func navigateTo(_ shelter: Shelter) {
        let placemark = MKPlacemark(coordinate: shelter.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = shelter.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
        ])
    }
}
