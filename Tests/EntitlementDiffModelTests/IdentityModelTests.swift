import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

@MainActor
final class IdentityModelTests: XCTestCase {
    func testSameNameSourcesSwapIdentityAndLocationTogether() async {
        let reader = IdentityReader(); let model = ComparisonModel(reader: reader)
        for (side,folder,version) in [(ComparisonSide.previous,"old","1"),(.current,"new","2")] {
            let url = URL(fileURLWithPath:"/synthetic/\(folder)/Same.app")
            let task = model.load(url, side:side);let request = await reader.next()
            await reader.finish(request, version:version);await task.value
        }
        XCTAssertTrue(model.swap())
        XCTAssertEqual(model.previous.snapshot?.identity?.version,"2")
        XCTAssertEqual(model.selectedSourceURL(for:.previous)?.path,"/synthetic/new/Same.app")
        XCTAssertEqual(model.current.snapshot?.identity?.version,"1")
        model.clear(.previous)
        XCTAssertNil(model.previous.snapshot?.identity)
        XCTAssertNil(model.selectedSourceURL(for:.previous))
    }
    func testLateIdentityCannotReplaceNewSelectionOrArchitectureClear() async {
        let reader = IdentityReader();let model = ComparisonModel(reader:reader,architecture:.arm64)
        let old = model.load(URL(fileURLWithPath:"/synthetic/old/Same.app"),side:.previous)
        let a = await reader.next()
        let new = model.load(URL(fileURLWithPath:"/synthetic/new/Same.app"),side:.previous)
        let b = await reader.next()
        await reader.finish(b,version:"2");await new.value
        await reader.finish(a,version:"1");await old.value
        XCTAssertEqual(model.previous.snapshot?.identity?.version,"2")
        XCTAssertEqual(model.selectedSourceURL(for:.previous)?.path,"/synthetic/new/Same.app")
        let reload = model.reload(.previous);let c = await reader.next()
        XCTAssertNil(model.previous.snapshot?.identity)
        model.setArchitecture(.x86_64)
        await reader.finish(c,version:"3");await reload?.value
        XCTAssertNil(model.previous.snapshot?.identity)
        XCTAssertNil(model.selectedSourceURL(for:.previous))
        model.loadExample();XCTAssertNil(model.selectedSourceURL(for:.previous))
    }
}
private actor IdentityReader: SnapshotReading {
    struct Request: Sendable { let id:UUID;let architecture:Architecture }
    var queued:[Request]=[]
    var consumers:[CheckedContinuation<Request,Never>]=[]
    var completions:[UUID:CheckedContinuation<EntitlementSnapshot,any Error>]=[:]
    func read(at url:URL,architecture:Architecture) async throws -> EntitlementSnapshot {
        try await withCheckedThrowingContinuation { completion in
            let request=Request(id:UUID(),architecture:architecture);completions[request.id]=completion
            if consumers.isEmpty { queued.append(request) } else { consumers.removeFirst().resume(returning:request) }
        }
    }
    func next() async -> Request {
        if !queued.isEmpty { return queued.removeFirst() }
        return await withCheckedContinuation { consumers.append($0) }
    }
    func finish(_ request:Request,version:String) {
        completions.removeValue(forKey:request.id)?.resume(returning:.init(sourceName:"Same.app",signingIdentifier:"test",architecture:request.architecture,entitlements:.init(),identity:.init(infoPlist:["CFBundleShortVersionString":version])))
    }
}
