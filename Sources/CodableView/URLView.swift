//
//  File.swift
//  
//
//  Created by Jaleel Akbashev on 23.05.21.
//

import SwiftUI
import Combine

public struct URLView: Codable, View, Identifiable {
    
    @ObservedObject var viewModel: URLViewModel
    
    var cancellables = Set<AnyCancellable>()

    public var id = UUID()
    public var url: URL
    
    public enum CodingKeys: String, CodingKey {
        case id
        case url
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encodeIfPresent(self.url, forKey: .url)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.url = try container.decode(URL.self, forKey: .url)
        self.viewModel = URLViewModel(url: url)
    }
    
    mutating func fetchView() {
        
    }
    
    public init(url: URL) {
        self.url = url
        self.viewModel = URLViewModel(url: url)
    }
    
    
    public var body: some View {
        if self.viewModel.contentView.type != nil {
            AnyView(self.viewModel.contentView)
        } else {
            VStack {
                Text("Loading...")
            }
        }
    }
}

class URLViewModel: ObservableObject {
    
    @Published private(set) var contentView: CodableView = CodableView()
    private var cancellable: AnyCancellable?
    
    init(url: URL) {
        self.cancellable = URLSession.shared
            .dataTaskPublisher(for: url)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return element.data
            }
            .decode(type: CodableView.self, decoder: JSONDecoder())
            .replaceError(with:
                            CodableView(
                                type: .VStack,
                                subviews: [
                                    CodableView(type: .Text, value: CodableView.Value(text: "Error"))
                                ]
                            )
            )
            .receive(on: RunLoop.main)
            .assign(to: \.contentView, on: self)
    }
}

