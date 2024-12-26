import SwiftUI
import CoreData

struct CoreDataDebugView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AgileRatesEntity.validFrom, ascending: true)],
        animation: .default)
    private var rates: FetchedResults<AgileRatesEntity>
    
    @State private var showingDeleteConfirmation = false
    @State private var searchText = ""
    @State private var selectedRate: AgileRatesEntity?
    
    var body: some View {
        NavigationView {
            VStack {
                Text("總行數: \(filteredRates.count)")
                    .font(.headline)
                    .padding()
                
                SearchBar(text: $searchText)
                
                VStack {
                    ColumnHeaders()
                    
                    List {
                        ForEach(filteredRates, id: \.self) { rate in
                            RateRow(rate: rate)
                                .onTapGesture {
                                    selectedRate = rate
                                }
                        }
                        .onDelete(perform: deleteRates)
                    }
                    .listStyle(PlainListStyle())
                }
                
                Button("刷新數據") {
                    refreshData()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .navigationTitle("Core Data 調試")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刪除全部") {
                        showingDeleteConfirmation = true
                    }
                }
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("確認刪除"),
                    message: Text("您確定要刪除所有數據嗎？"),
                    primaryButton: .destructive(Text("刪除")) {
                        deleteAllRates()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(item: $selectedRate) { rate in
                RateDetailView(rate: rate)
            }
        }
    }
    
    private var filteredRates: [AgileRatesEntity] {
        if searchText.isEmpty {
            return Array(rates)
        } else {
            return rates.filter { rate in
                formatDate(rate.validFrom).contains(searchText) ||
                formatDate(rate.validTo).contains(searchText) ||
                String(format: "%.4f", rate.valueIncVat).contains(searchText)
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func deleteRates(at offsets: IndexSet) {
        withAnimation {
            offsets.map { rates[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("刪除失敗: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteAllRates() {
        withAnimation {
            rates.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("刪除所有數據失敗: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func refreshData() {
        viewContext.reset()
        do {
            let fetchRequest: NSFetchRequest<AgileRatesEntity> = AgileRatesEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AgileRatesEntity.validFrom, ascending: true)]
            let results = try viewContext.fetch(fetchRequest)
            print("刷新數據成功，獲取到 \(results.count) 條記錄")
        } catch {
            print("刷新數據時出錯: \(error)")
        }
    }
}

struct ColumnHeaders: View {
    var body: some View {
        HStack {
            Text("開始時間")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("結束時間")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("價格 (含稅)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("搜索...", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
        }
        .padding(.horizontal)
    }
}

struct RateRow: View {
    let rate: AgileRatesEntity
    
    var body: some View {
        HStack {
            Text(formatDate(rate.validFrom))
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(formatDate(rate.validTo))
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(format: "%.4f", rate.valueIncVat))
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct RateDetailView: View {
    let rate: AgileRatesEntity
    
    var body: some View {
        VStack(spacing: 20) {
            Text("費率詳情")
                .font(.largeTitle)
                .padding()
            
            DetailRow(title: "開始時間", value: formatDate(rate.validFrom))
            DetailRow(title: "結束時間", value: formatDate(rate.validTo))
            DetailRow(title: "含稅價格", value: String(format: "%.4f", rate.valueIncVat))
            DetailRow(title: "不含稅價格", value: String(format: "%.4f", rate.valueExcVat))
            
            Spacer()
        }
        .padding()
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding(.horizontal)
    }
}

struct CoreDataDebugView_Previews: PreviewProvider {
    static var previews: some View {
        CoreDataDebugView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}

// 添加這個結構體來支持預覽
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WJ_OctopusAgile")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("無法加載持久化存儲: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}