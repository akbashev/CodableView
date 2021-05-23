//
//  File.swift
//  
//
//  Created by Jaleel Akbashev on 23.05.21.
//

import SwiftUI
import Combine

public struct URLView: Codable, View, Identifiable {
    
    @State var contentView: CodableView = CodableView(type: .Text, value: CodableView.Value(text: "Error"))
    private var cancellable: AnyCancellable?

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
        cancellable = URLSession.shared
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
            .assign(to: \.contentView, on: self)
    }
    
    public init(url: URL) {
        self.url = url

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
            .assign(to: \.contentView, on: self)
    }
    
    
    public var body: some View {
        if self.contentView.subviews?.first?.value?.text != "Error"  {
            contentView
        } else {
            ActivityIndicator(isAnimating: true)
//                .configure { $0.color = .yellow } // Optional configurations (🎁 bouns)
//                .background(Color.blue)
        }
    }
}



struct ActivityIndicator: UIViewRepresentable {
    
    typealias UIView = UIActivityIndicatorView
    var isAnimating: Bool
    fileprivate var configuration = { (indicator: UIView) in }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView { UIView() }
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        configuration(uiView)
    }
}
