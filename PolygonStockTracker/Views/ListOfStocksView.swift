//
//  ListView.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/2/24.
//

import SwiftUI

struct ListOfStocksView: View {
    @State var showAddView: Bool = false
    @ObservedObject var viewModel: ViewModel
    private var networkService: NetworkServicable
    
    init(persistence: Storable, networkService: NetworkServicable) {
        self.viewModel = ViewModel(persistence: persistence)
        self.networkService = networkService
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(self.viewModel.stocks, id: \.self) { item in
                        Text(item.ticker)
                    }
                    .onDelete(perform: deleteStocks)
                }
                .padding()
            }
            .navigationBarTitle(Constants.listOfStocks, displayMode: .inline)
            .sheet(isPresented: $showAddView,
                   onDismiss: self.viewModel.setupStocks,
                   content: {
                AddSheet(persistence: self.viewModel.persistenceService,
                         networkService: self.networkService, 
                         showAddView: self.$showAddView)
            })
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    self.showAddView = true
                }, label: {
                    Label("Add", systemImage:"plus")
                        .foregroundColor(Color.gray)
                })
            }
        }
    }
    
    func deleteStocks(_ offsets: IndexSet) {
        self.viewModel.removeStockAt(offsets: offsets)
    }
}

struct AddSheet: View {
    @Environment(\.presentationMode) var presentation
    let persistence: Storable
    let networkService: NetworkServicable
    @Binding var showAddView: Bool
    
    init(persistence: Storable,
         networkService: NetworkServicable,
         showAddView: Binding<Bool>) {
        self.persistence = persistence
        self.networkService = networkService
        self._showAddView = showAddView
    }
    
    var body: some View {
        VStack {
            SearchView(persistence: self.persistence,
                       networkService: self.networkService,
                       showAddView: self.$showAddView)
            Spacer()
            Button(Constants.dismiss) {
                self.presentation.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    ListOfStocksView(persistence: PersistenceService(), networkService: NetworkService())
}
