//
//  ViewController.swift
//  BeaconAPITest080701
//
//  Created by jh on 6/11/25.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        let buttonA = UIButton(type: .system)
        buttonA.setTitle("비콘 발신기로 등록", for: .normal)
        buttonA.translatesAutoresizingMaskIntoConstraints = false
        buttonA.addTarget(self, action: #selector(goToA), for: .touchUpInside)
        view.addSubview(buttonA)

        let buttonB = UIButton(type: .system)
        buttonB.setTitle("비콘 신호 수신하기", for: .normal)
        buttonB.translatesAutoresizingMaskIntoConstraints = false
        buttonB.addTarget(self, action: #selector(goToB), for: .touchUpInside)
        view.addSubview(buttonB)

        NSLayoutConstraint.activate([
            buttonA.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonA.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            buttonB.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonB.topAnchor.constraint(equalTo: buttonA.bottomAnchor, constant: 20)
        ])
    }

    @objc func goToA() {
        let vc = SendViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func goToB() {
        let vc = ReceivedViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
