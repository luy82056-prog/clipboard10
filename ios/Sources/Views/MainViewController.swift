import UIKit

class MainViewController: UIViewController {
    private let tableView = UITableView()
    private let clipboardManager = ClipboardManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .clipboardUpdated, object: nil)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 1.0, green: 0.973, blue: 0.906, alpha: 1.0)

        let headerView = UIView()
        headerView.backgroundColor = UIColor(red: 1.0, green: 0.973, blue: 0.906, alpha: 1.0)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let iconLabel = UILabel()
        iconLabel.text = "📋"
        iconLabel.font = .systemFont(ofSize: 28)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(iconLabel)

        let titleLabel = UILabel()
        titleLabel.text = "Clipboard10"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "最近10条复制记录"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(subtitleLabel)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(red: 1.0, green: 0.973, blue: 0.906, alpha: 1.0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ClipboardCell.self, forCellReuseIdentifier: "ClipboardCell")
        view.addSubview(tableView)

        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        let copyAllBtn = createButton(title: "📋 复制全部", color: .systemOrange)
        copyAllBtn.addTarget(self, action: #selector(copyAllTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(copyAllBtn)

        let dedupBtn = createButton(title: "🔄 去重", color: .systemGray)
        dedupBtn.addTarget(self, action: #selector(dedupTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(dedupBtn)

        let clearBtn = createButton(title: "🗑️ 清空", color: .systemRed)
        clearBtn.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(clearBtn)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 70),

            iconLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 18),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -8),

            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func createButton(title: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = color.withAlphaComponent(0.15)
        btn.setTitleColor(color, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.layer.cornerRadius = 8
        return btn
    }

    @objc private func reloadData() {
        tableView.reloadData()
    }

    @objc private func copyAllTapped() {
        let text = clipboardManager.copyAll()
        UIPasteboard.general.string = text
        showToast("已复制全部内容")
    }

    @objc private func dedupTapped() {
        clipboardManager.dedupe()
        tableView.reloadData()
    }

    @objc private func clearTapped() {
        let alert = UIAlertController(title: "确认清空", message: "确定要清空全部剪贴板历史吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认", style: .destructive) { [weak self] _ in
            self?.clipboardManager.clearAll()
            self?.tableView.reloadData()
        })
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toast.textAlignment = .center
        toast.font = .systemFont(ofSize: 14)
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            toast.widthAnchor.constraint(equalToConstant: 160),
            toast.heightAnchor.constraint(equalToConstant: 36)
        ])

        UIView.animate(withDuration: 0.3, delay: 1.0, options: .curveEaseOut) {
            toast.alpha = 0
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipboardManager.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ClipboardCell", for: indexPath) as! ClipboardCell
        let item = clipboardManager.items[indexPath.row]
        cell.configure(with: item, index: indexPath.row)
        cell.onCopy = { [weak self] in
            self?.clipboardManager.copyItem(item)
            self?.showToast("已复制")
        }
        cell.onDelete = { [weak self] in
            self?.clipboardManager.deleteItem(at: indexPath.row)
            self?.tableView.reloadData()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
}

class ClipboardCell: UITableViewCell {
    var onCopy: (() -> Void)?
    var onDelete: (() -> Void)?

    private let indexLabel = UILabel()
    private let contentLabel = UILabel()
    private let copyBtn = UIButton(type: .system)
    private let deleteBtn = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 1.0, green: 0.973, blue: 0.906, alpha: 1.0)
        selectionStyle = .none

        indexLabel.font = .systemFont(ofSize: 12, weight: .bold)
        indexLabel.textColor = .white
        indexLabel.textAlignment = .center
        indexLabel.backgroundColor = .systemOrange
        indexLabel.layer.cornerRadius = 10
        indexLabel.clipsToBounds = true
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(indexLabel)

        contentLabel.font = .systemFont(ofSize: 14)
        contentLabel.numberOfLines = 2
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentLabel)

        copyBtn.setTitle("📋", for: .normal)
        copyBtn.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        copyBtn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(copyBtn)

        deleteBtn.setTitle("🗑️", for: .normal)
        deleteBtn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteBtn)

        NSLayoutConstraint.activate([
            indexLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            indexLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            indexLabel.widthAnchor.constraint(equalToConstant: 24),
            indexLabel.heightAnchor.constraint(equalToConstant: 24),

            contentLabel.leadingAnchor.constraint(equalTo: indexLabel.trailingAnchor, constant: 12),
            contentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: copyBtn.leadingAnchor, constant: -8),

            copyBtn.trailingAnchor.constraint(equalTo: deleteBtn.leadingAnchor, constant: -8),
            copyBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            copyBtn.widthAnchor.constraint(equalToConstant: 36),
            copyBtn.heightAnchor.constraint(equalToConstant: 36),

            deleteBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteBtn.widthAnchor.constraint(equalToConstant: 36),
            deleteBtn.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    func configure(with item: ClipboardItem, index: Int) {
        indexLabel.text = "\(index + 1)"
        contentLabel.text = item.content
    }

    @objc private func copyTapped() {
        onCopy?()
    }

    @objc private func deleteTapped() {
        onDelete?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}