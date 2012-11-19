//
//  WLTabBarController.m
//  WLContainerControllers
//
//  Created by Ling Wang on 8/25/11.
//  Copyright (c) 2011 I Wonder Phone. All rights reserved.
//

#import "WLTabBarController.h"

#define kTabBarHeightPortrait 44
#define kTabBarHeightLandscape 32




@implementation WLTabBarController

@synthesize tabBar = _tabBar;


#pragma mark - View lifecycle

- (void)viewDidLoad
{
	if (self.navigationController) {
		UIBarButtonItem *tabBar = [[UIBarButtonItem alloc] initWithCustomView:self.tabBar];
		self.toolbarItems = [NSArray arrayWithObject:tabBar];
		self.navigationController.toolbarHidden = NO;
	} else {
		[self.view addSubview:self.tabBar];
	}
	
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// !!!: Must postpone tab bar setup till now to allow customization in viewDidLoad of subclasses.
	if (self.tabBar.items.count == 0 && self.viewControllers.count != 0) {
		NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.viewControllers.count];
		for (UIViewController *controller in self.viewControllers) {
			[items addObject:controller.tabBarItem];
		}
		self.tabBar.items = items;
		self.tabBar.selectedItem = self.selectedViewController.tabBarItem;
	}
}

- (void)didReceiveMemoryWarning {
	if (self.isViewLoaded && self.view.window == nil) {
		_tabBar = nil;
	}
	[super didReceiveMemoryWarning];
}



#pragma mark - Accessing the Tab Bar Controller Properties

- (WLTabBar *)tabBar {
	if (_tabBar == nil) {
		_tabBar = [WLTabBar new];
		_tabBar.delegate = self;
	}
	
	return _tabBar;
}



#pragma mark - Managing the View Controllers

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
	if ([self.viewControllers isEqualToArray:viewControllers]) return;
	
	// Update the tab bar.
	NSMutableArray *items = [NSMutableArray arrayWithCapacity:viewControllers.count];
	for (UIViewController *controller in viewControllers) {
		[items addObject:controller.tabBarItem];
	}
	[self.tabBar setItems:items animated:animated];
	[super setViewControllers:viewControllers animated:animated];
}

- (BOOL)replaceViewControllerAtIndex:(NSUInteger)index withViewController:(UIViewController *)newViewController {
	if ([super replaceViewControllerAtIndex:index withViewController:newViewController]) {
		if (_tabBar != nil && newViewController.tabBarItem != [_tabBar.items objectAtIndex:index]) {
			[_tabBar replaceItemAtIndex:index withItem:newViewController.tabBarItem];
		}
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)exchangeViewControllerAtIndex:(NSUInteger)index1 withViewControllerAtIndex:(NSUInteger)index2 {
	if ([super exchangeViewControllerAtIndex:index1 withViewControllerAtIndex:index2]) {
		if (_tabBar != nil && ((UIViewController *)[self.viewControllers objectAtIndex:index1]).tabBarItem != [_tabBar.items objectAtIndex:index1]) {
			[_tabBar exchangeItemAtIndex:index1 withItemAtIndex:index2];
		}
		return YES;
	} else {
		return NO;
	}
}



#pragma mark - Managing the Selected View Controller

- (void)setSelectedViewController:(UIViewController *)viewController {	
	[super setSelectedViewController:viewController];
	_tabBar.selectedItem = viewController.tabBarItem;
}



#pragma mark - Managing the Content View

- (void)layoutContentView:(UIView *)contentView {
	UIToolbar *toolbar = self.navigationController.toolbar;
	if (toolbar) {
		CGRect tabBarFrame = toolbar.bounds;
		_tabBar.frame = tabBarFrame;
		_tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;	
	} else {
		CGRect tabBarFrame = self.view.bounds;
		tabBarFrame.size.height = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? kTabBarHeightPortrait : kTabBarHeightLandscape;
		tabBarFrame.origin.y = CGRectGetMaxY(self.view.bounds) - tabBarFrame.size.height;
		_tabBar.frame = tabBarFrame;
		_tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;	
	}
	
	if (contentView.superview != self.view) return;
	
	contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	// Adjust the frame of the content view according to the insets and tab bar size.
	CGRect contentFrame = self.view.bounds;
	if (_tabBar.superview == contentView.superview) {
		contentFrame.size.height -= self.tabBar.frame.size.height;
	}
	contentView.frame = UIEdgeInsetsInsetRect(contentFrame, self.contentInset);
}



#pragma mark - WLTabBarDelegate

- (void)tabBar:(WLTabBar *)tabBar didSelectItem:(UITabBarItem *)item {
	NSUInteger index = [tabBar.items indexOfObjectIdenticalTo:item];
	UIViewController *vc = [self.viewControllers objectAtIndex:index];
	if (vc.tabBarItem == item) {
		if (self.selectedViewController != vc) {
			self.selectedViewController = vc;
		}
	}
}

- (void)tabBar:(WLTabBar *)tabBar didTapTabForSelectedItem:(UITabBarItem *)item {
	if ([_delegate respondsToSelector:@selector(tabBarController:didTapTabForSelectedViewController:)]) {
		[_delegate tabBarController:self didTapTabForSelectedViewController:self.selectedViewController];
	}
}

- (void)tabBar:(WLTabBar *)tabBar didDoubleTapTabForItem:(UITabBarItem *)item {
	if ([_delegate respondsToSelector:@selector(tabBarController:didDoubleTapTabForViewController:)]) {
		NSUInteger index = [tabBar.items indexOfObjectIdenticalTo:item];
		UIViewController *vc = [self.viewControllers objectAtIndex:index];
		[_delegate tabBarController:self didDoubleTapTabForViewController:vc];
	}
}

- (void)tabBar:(WLTabBar *)tabBar willBeginCustomizingItem:(UITabBarItem *)item {
	if ([_delegate respondsToSelector:@selector(tabBarController:willBeginCustomizingViewController:)]) {
		UIViewController *viewController = [self.viewControllers objectAtIndex:[tabBar.items indexOfObjectIdenticalTo:item]];
		[_delegate tabBarController:self willBeginCustomizingViewController:viewController];
	}
}

- (void)tabBar:(WLTabBar *)tabBar didBeginCustomizingItem:(UITabBarItem *)item {
	
}

- (void)tabBar:(WLTabBar *)tabBar willEndCustomizingItem:(UITabBarItem *)item newItem:(UITabBarItem *)newItem {
	if ([_delegate respondsToSelector:@selector(tabBarController:willEndCustomizingViewController:newViewController:)]) {
		UIViewController *viewController = [self.viewControllers objectAtIndex:[tabBar.items indexOfObjectIdenticalTo:item]];
		UIViewController *newViewController = [self.viewControllers objectAtIndex:[tabBar.items indexOfObjectIdenticalTo:newItem]];
		[_delegate tabBarController:self willEndCustomizingViewController:viewController newViewController:newViewController];
	}	
}

- (void)tabBar:(WLTabBar *)tabBar didEndCustomizingItem:(UITabBarItem *)item newItem:(UITabBarItem *)newItem {
	NSUInteger index1 = [tabBar.items indexOfObjectIdenticalTo:item];
	NSUInteger index2 = [tabBar.items indexOfObjectIdenticalTo:newItem];
	[self exchangeViewControllerAtIndex:index1 withViewControllerAtIndex:index2];
	if ([_delegate respondsToSelector:@selector(tabBarController:didEndCustomizingViewController:newViewController:)]) {
		UIViewController *viewController = [self.viewControllers objectAtIndex:[tabBar.items indexOfObjectIdenticalTo:item]];
		UIViewController *newViewController = [self.viewControllers objectAtIndex:[tabBar.items indexOfObjectIdenticalTo:newItem]];
		[_delegate tabBarController:self didEndCustomizingViewController:viewController newViewController:newViewController];
	}	
}



@end
