
import UIKit
import WMF

protocol ArticleAsLivingDocViewControllerDelegate: class {
    func fetchNextPage(nextRvStartId: UInt)
    var articleAsLivingDocViewModel: ArticleAsLivingDocViewModel? {
        get
    }
}

@available(iOS 13.0, *)
class ArticleAsLivingDocViewController: ColumnarCollectionViewController {
    
    private let articleTitle: String?
    private var headerView: ArticleAsLivingDocHeaderView?
    private let headerText = WMFLocalizedString("aaald-header-text", value: "Recent Changes", comment: "Header text of article as a living document view.")
    private let editMetrics: [NSNumber]?
    private weak var delegate: ArticleAsLivingDocViewControllerDelegate?
    
    private var dataSource: UICollectionViewDiffableDataSource<ArticleAsLivingDocViewModel.SectionHeader, ArticleAsLivingDocViewModel.TypedEvent>!
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    required init?(articleAsLivingDocViewModel: ArticleAsLivingDocViewModel, articleTitle: String?, editMetrics: [NSNumber]?, theme: Theme, locale: Locale = Locale.current, delegate: ArticleAsLivingDocViewControllerDelegate) {
        
        guard let _ = delegate.articleAsLivingDocViewModel else {
            return nil
        }
        
        self.articleTitle = articleTitle
        self.editMetrics = editMetrics
        super.init()
        self.theme = theme
        self.delegate = delegate
        
        dataSource = UICollectionViewDiffableDataSource<ArticleAsLivingDocViewModel.SectionHeader, ArticleAsLivingDocViewModel.TypedEvent>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, event: ArticleAsLivingDocViewModel.TypedEvent) -> UICollectionViewCell? in
            
            let cell: CollectionViewCell
            switch event {
            case .large(let largeEvent):
                guard let largeEventCell = collectionView.dequeueReusableCell(withReuseIdentifier: ArticleAsLivingDocLargeEventCollectionViewCell.identifier, for: indexPath) as? ArticleAsLivingDocLargeEventCollectionViewCell else {
                    return nil
                }
                
                largeEventCell.configure(with: largeEvent, theme: theme)
                cell = largeEventCell
                //tonitodo: look into this commented out need
                //significantEventsSideScrollingCell.timelineView.extendTimelineAboveDot = indexPath.item == 0 ? true : false
            case .small(let smallEvent):
                guard let smallEventCell = collectionView.dequeueReusableCell(withReuseIdentifier: ArticleAsLivingDocSmallEventCollectionViewCell.identifier, for: indexPath) as? ArticleAsLivingDocSmallEventCollectionViewCell else {
                    return nil
                }
                
                smallEventCell.configure(viewModel: smallEvent, theme: theme)
                cell = smallEventCell
            }
            
            if let layout = collectionView.collectionViewLayout as? ColumnarCollectionViewLayout {
                cell.layoutMargins = layout.itemLayoutMargins
            }
            
            return cell
            
        }
        

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in

            guard kind == UICollectionView.elementKindSectionHeader else {
                return UICollectionReusableView()
            }
            
            let section = self.dataSource.snapshot()
                .sectionIdentifiers[indexPath.section]
            
            guard let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ArticleAsLivingDocSectionHeaderView.identifier, for: indexPath) as? ArticleAsLivingDocSectionHeaderView else {
                return UICollectionReusableView()
            }
            
            sectionHeaderView.configure(viewModel: section, theme: theme)
            return sectionHeaderView
            
        }
    }
    
    func addInitialSections(sections: [ArticleAsLivingDocViewModel.SectionHeader]) {
        var snapshot = NSDiffableDataSourceSnapshot<ArticleAsLivingDocViewModel.SectionHeader, ArticleAsLivingDocViewModel.TypedEvent>()
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(section.typedEvents, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func appendSections(_ sections: [ArticleAsLivingDocViewModel.SectionHeader]) {
        
        var currentSnapshot = dataSource.snapshot()
        
        var existingSections: [ArticleAsLivingDocViewModel.SectionHeader] = []
        for currentSection in currentSnapshot.sectionIdentifiers {
            for proposedSection in sections {
                if currentSection == proposedSection {
                    currentSnapshot.appendItems(proposedSection.typedEvents, toSection: currentSection)
                    existingSections.append(proposedSection)
                }
            }
        }
        
        for section in sections {
            if !existingSections.contains(section) {
                currentSnapshot.appendSections([section])
                currentSnapshot.appendItems(section.typedEvents, toSection: section)
            }
        }
        
        dataSource.apply(currentSnapshot, animatingDifferences: true)
    }
    
    func reloadData() {
        collectionView.reloadData()
    }

    override func viewDidLoad() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("close-button", value: "Close", comment: "Close button used in navigation bar that closes out a presented modal screen."), style: .done, target: self, action: #selector(closeButtonPressed))
        
        super.viewDidLoad()

        layoutManager.register(ArticleAsLivingDocLargeEventCollectionViewCell.self, forCellWithReuseIdentifier: ArticleAsLivingDocLargeEventCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ArticleAsLivingDocSmallEventCollectionViewCell.self, forCellWithReuseIdentifier: ArticleAsLivingDocSmallEventCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ArticleAsLivingDocSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ArticleAsLivingDocSectionHeaderView.identifier, addPlaceholder: true)
        
        self.title = headerText
        
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        
        navigationMode = .forceBar
        if let headerView = ArticleAsLivingDocHeaderView.wmf_viewFromClassNib() {
            self.headerView = headerView
            configureHeaderView(headerView)
            navigationBar.isBarHidingEnabled = false
            navigationBar.isUnderBarViewHidingEnabled = true
            useNavigationBarVisibleHeightForScrollViewInsets = true
            navigationBar.addUnderNavigationBarView(headerView)
            navigationBar.underBarViewPercentHiddenForShowingTitle = 0.6
            navigationBar.title = headerText
            navigationBar.setNeedsLayout()
            navigationBar.layoutIfNeeded()
            updateScrollViewInsets()
        }
    }
    
    @objc private func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    private func configureHeaderView(_ headerView: ArticleAsLivingDocHeaderView) {
        
        guard let articleAsLivingDocViewModel = delegate?.articleAsLivingDocViewModel else {
            return
        }
        
        let headerText = self.headerText.uppercased(with: NSLocale.current)
        headerView.configure(headerText: headerText, titleText: articleTitle, summaryText: articleAsLivingDocViewModel.summaryText, editMetrics: editMetrics, theme: theme)
        headerView.apply(theme: theme)
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 70)
        
        let section = self.dataSource.snapshot()
            .sectionIdentifiers[section]
        
        guard let sectionHeaderView = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ArticleAsLivingDocSectionHeaderView.identifier) as? ArticleAsLivingDocSectionHeaderView else {
            return estimate
        }
        
        sectionHeaderView.configure(viewModel: section, theme: theme)
        
        estimate.height = sectionHeaderView.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 350)
        
        guard let event = dataSource.itemIdentifier(for: indexPath) else {
            return estimate
        }
        
        let cell: CollectionViewCell
        switch event {
        case .large(let largeEvent):
            guard let largeEventCell = layoutManager.placeholder(forCellWithReuseIdentifier: ArticleAsLivingDocLargeEventCollectionViewCell.identifier) as? ArticleAsLivingDocLargeEventCollectionViewCell else {
                return estimate
            }
            
            
            largeEventCell.configure(with: largeEvent, theme: theme)
            cell = largeEventCell
        case .small(let smallEvent):
            guard let smallEventCell = layoutManager.placeholder(forCellWithReuseIdentifier: ArticleAsLivingDocSmallEventCollectionViewCell.identifier) as? ArticleAsLivingDocSmallEventCollectionViewCell else {
                return estimate
            }
            
            smallEventCell.configure(viewModel: smallEvent, theme: theme)
            cell = smallEventCell
        }
        
        cell.layoutMargins = layout.itemLayoutMargins
        estimate.height = cell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        
        return estimate
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let articleAsLivingDocViewModel = delegate?.articleAsLivingDocViewModel else {
            return
        }
        
        let numSections = dataSource.numberOfSections(in: collectionView)
        let numEvents = dataSource.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        
        if indexPath.section == numSections - 1 &&
            indexPath.item == numEvents - 1 {
            guard let nextRvStartId = articleAsLivingDocViewModel.nextRvStartId,
                  nextRvStartId != 0 else {
                return
            }
            
            delegate?.fetchNextPage(nextRvStartId: nextRvStartId)
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func apply(theme: Theme) {
        guard isViewLoaded else {
            return
        }

        super.apply(theme: theme)
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        navigationController?.navigationBar.barTintColor = theme.colors.cardButtonBackground //tonitodo: this doesn't seem to work
    }
}