import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let viewController = TasksListViewContoller()
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = true
        window.rootViewController = navigationController
        configureNavbarTitle()
        window.makeKeyAndVisible()
        self.window = window
    }

    private func configureNavbarTitle() {
        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = 16
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedString.Key.paragraphStyle: style]
    }
}
