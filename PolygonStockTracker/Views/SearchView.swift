//
//  SearchView.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/2/24.
//

import SwiftUI

struct SearchView: View {
    
    @State var textInput: String = ""
    @State var resetSearch: Bool = false
    @Binding var showAddView: Bool
    @ObservedObject var viewModel: ViewModel
    
    init(persistence: Storable, networkService: NetworkServicable, showAddView: Binding<Bool>) {
        viewModel = ViewModel(networkService: networkService, persistence: persistence)
        self._showAddView = showAddView
    }
    
    fileprivate func textFieldContainsStringValue(_ input: String) -> Bool {
        return input.count >= 1
    }
    
    var body: some View {
        VStack {
            SearchBarView(textInput: $textInput, resetSearch: $resetSearch)
            List(self.viewModel.stockTickers?.results ?? [], id: \.id) { stock in // cannot use capture list here.
                HStack {
                    Text(stock.name)
                        .onTapGesture {
                            self.viewModel.didSelectStockToAdd(ticker: stock.ticker)
                            self.showAddView = false
                        }
                    Spacer()
                    Text(stock.ticker)
                }
            }
        }
        .onChange(of: textInput) { _, input in // cannot use capture list here.
            if textFieldContainsStringValue(input) {
                Task {
                    self.viewModel.startTimer(input)
                }
            }
        }
        .onChange(of: resetSearch) { _, shouldReset in // cannot use capture list here. 
            self.updateListForReset(shouldReset)
        }
    }
    
    private func updateListForReset(_ reset: Bool) {
        if reset {
            self.resetSearch = false
            self.viewModel.clearTickers()
        }
    }
}
    
struct SearchBarView: View {
    
    enum FocusedField {
        case search
    }
    
    @Binding var textInput: String
    @Binding var resetSearch: Bool
    @FocusState private var isSearchFieldFocused: Bool
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField(Constants.searchStaticText, text: $textInput)
                .focused($isSearchFieldFocused)
            Button(action: {
                textInput = ""
                resetSearch = true
                isSearchFieldFocused = false
            }, label: {
                Image(systemName: "x.circle")
                    .foregroundColor(Color.gray)
            })
        }
        .onAppear {
            self.isSearchFieldFocused = true
        }
        .padding()
    }
}

#Preview {
    SearchView(persistence: PersistenceService(), networkService: NetworkService(), showAddView: .constant(true))
}
