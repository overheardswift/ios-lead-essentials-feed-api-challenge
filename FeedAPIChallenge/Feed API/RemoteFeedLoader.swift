//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard self != nil else { return }

			switch result {
			case let .success((data, response)):
				completion(FeedImagesMapper.map(data, response))
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}
	
	private final class FeedImagesMapper {
		
		private struct Root: Decodable {
			private let images: [Image]

			var feedImages: [FeedImage] {
				return images.map { $0.image }
			}

			enum CodingKeys: String, CodingKey {
				case images = "items"
			}
		}

		private struct Image: Decodable {
			private let id: UUID
			private let description: String?
			private let location: String?
			private let url: URL

			var image: FeedImage {
				return FeedImage(
					id: id,
					description: description,
					location: location,
					url: url
				)
			}

			enum CodingKeys: String, CodingKey {
				case id = "image_id"
				case description = "image_desc"
				case location = "image_loc"
				case url = "image_url"
			}
		}
		
		static func map(_ data: Data, _ response: HTTPURLResponse) -> FeedLoader.Result {
			guard response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
				return .failure(Error.invalidData)
			}
			return .success(root.feedImages)
		}
	}
	
}
