//
//  PFDashboardContentView.swift
//  Planet
//
//  Created by Kai on 12/18/22.
//

import Foundation
import SwiftUI
import WebKit


struct PFDashboardContentView: NSViewRepresentable {
    
    @Binding var url: URL
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> PFDashboardWebView {
        let wv = PFDashboardWebView()
        wv.navigationDelegate = context.coordinator
        wv.setValue(false, forKey: "drawsBackground")
        wv.load(URLRequest(url: url))
        wv.allowsBackForwardNavigationGestures = false
        NotificationCenter.default.addObserver(forName: .dashboardLoadPreviewURL, object: nil, queue: .main) { n in
            let targetURL: URL
            if let previewURL = n.object as? URL {
                targetURL = previewURL
                if wv.canGoBack, let backItem = wv.backForwardList.backList.first {
                    wv.go(to: backItem)
                }
            } else if let currentURL = PlanetPublishedServiceStore.shared.selectedFolderCurrentURL {
                targetURL = currentURL
            } else {
                targetURL = self.url
            }
            wv.load(URLRequest(url: targetURL))
        }
        NotificationCenter.default.addObserver(forName: .dashboardProcessDirectoryURL, object: nil, queue: nil) { n in
            Task { @MainActor in
                try? await wv.evaluateJavaScript("document.getElementById('page-header').outerHTML = '';")
            }
        }
        NotificationCenter.default.addObserver(forName: .dashboardWebViewGoForward, object: nil, queue: .main) { _ in
            wv.goForward()
        }
        NotificationCenter.default.addObserver(forName: .dashboardWebViewGoBackward, object: nil, queue: .main) { _ in
            wv.goBack()
        }
        NotificationCenter.default.addObserver(forName: .dashboardReloadWebView, object: nil, queue: .main) { _ in
            wv.reload()
        }
        NotificationCenter.default.addObserver(forName: .dashboardWebViewGoHome, object: nil, queue: .main) { _ in
            if wv.canGoBack, let backItem = wv.backForwardList.backList.first {
                if backItem.url.lastPathComponent == "NoSelection.html" {
                    if let secondLastItem = wv.backForwardList.backList.dropFirst().first {
                        wv.go(to: secondLastItem)
                    }
                    return
                }
                wv.go(to: backItem)
            } else {
                let serviceStore = PlanetPublishedServiceStore.shared
                serviceStore.restoreSelectedFolderNavigation()
            }
        }
        return wv
    }
    
    func updateNSView(_ nsView: PFDashboardWebView, context: Context) {
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: PFDashboardContentView
        
        init(_ parent: PFDashboardContentView) {
            self.parent = parent
        }
        
        // MARK: - NavigationDelegate
        
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            completionHandler(.performDefaultHandling, nil)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
//            if let url = navigationAction.request.url {
//                debugPrint("dashboard decide policy for url: \(url)")
//            }
            return (.allow, preferences)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let serviceStore = PlanetPublishedServiceStore.shared
            guard let currentURL = webView.url else { return }
            Task { @MainActor in
                serviceStore.updateSelectedFolderNavigation(withCurrentURL: currentURL, canGoForward: webView.canGoForward, forwardURL: webView.backForwardList.forwardItem?.url, canGoBackward: webView.canGoBack, backwardURL: webView.backForwardList.backItem?.url)
            }
//            debugPrint("dashboard finished url: \(currentURL)")
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            let serviceStore = PlanetPublishedServiceStore.shared
            guard let currentURL = webView.url else { return }
            guard let selectedID = serviceStore.selectedFolderID, let currentFolder = serviceStore.publishedFolders.first(where: { $0.id == selectedID }) else { return }
            Task (priority: .userInitiated) {
                let hasHTMLContent = await serviceStore.folderDirectoryContentHasHTMLContent(currentURL)
                debugPrint("[\(currentFolder.url.lastPathComponent)] url: \(currentURL) has html content -> \(hasHTMLContent)")
                if !hasHTMLContent {
                    let info = ["folder": currentFolder, "url": currentURL]
                    NotificationCenter.default.post(name: .dashboardProcessDirectoryURL, object: info)
                }
            }
//            debugPrint("dashboard commit url: \(currentURL)")
        }
    }
}
