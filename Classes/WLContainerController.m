//
//  WLContainerController.m
//  WLContainerController
//
//  Created by Wang Ling on 7/16/10.
//  Copyright I Wonder Phone 2010. All rights reserved.
//

#import "WLContainerController.h"

@interface WLContainerController ()
- (void)unregisterKVOForNavigationBar;
- (void)unregisterKVOForToolbar;
@end



@implementation WLContainerController


- (void)dealloc {
	[self unregisterKVOForNavigationBar];
	[self unregisterKVOForToolbar];
}

- (void)didReceiveMemoryWarning {
	if (self.isViewLoaded && self.view.window == nil) {
		self.toolbarItems = nil;
		self.view = nil;
	}
	[super didReceiveMemoryWarning];
}

- (void)unregisterKVOForNavigationBar {
	// Removing observer throws NSException if it is not a registered observer, but there is no way to query whether it is or not so I have to try removing anyhow.
	@try {
		[_contentController removeObserver:self forKeyPath:@"title"];
	}
	@catch (NSException *exception) {
		
	}
	
	@try {
		[_contentController removeObserver:self forKeyPath:@"navigationItem.title"];
	}
	@catch (NSException *exception) {
		
	}
	
	@try {
		[_contentController removeObserver:self forKeyPath:@"navigationItem.titleView"];
	}
	@catch (NSException * e) {

	}
	
	@try {
		[_contentController removeObserver:self forKeyPath:@"navigationItem.leftBarButtonItem"];
	}
	@catch (NSException * e) {

	}
	
	@try {
		[_contentController removeObserver:self forKeyPath:@"navigationItem.rightBarButtonItem"];
	}
	@catch (NSException * e) {

	}
	
	@try {
		[_contentController removeObserver:self forKeyPath:@"navigationItem.backBarButtonItem"];
	}
	@catch (NSException * e) {

	}
}

- (void)unregisterKVOForToolbar {
	// Removing observer throws NSRangeException if it is not a registered observer, but there is no way to query whether it is or not so I have to try removing anyhow.
	@try {
		[_contentController removeObserver:self forKeyPath:@"toolbarItems"];
	}
	@catch (NSException * e) {

	}
}


#pragma mark - Content View management

- (void)setContentController:(UIViewController *)contentController {
	if (_contentController == contentController) return;

	if (self.isViewLoaded) {
		[self updateNavigationBarFrom:contentController];
		[self updateToolbarFrom:contentController];
	}

	[_contentController willMoveToParentViewController:nil];
	[self addChildViewController:contentController];
	if (self.isViewLoaded) {
		if (_contentController.view.superview == self.view) {
			[_contentController.view removeFromSuperview];
		}
		if (contentController.view.superview != self.view) {
			[self.view addSubview:contentController.view];
		}
	}
	[contentController didMoveToParentViewController:self];	
	[_contentController removeFromParentViewController];
	
	_contentController = contentController;
}


- (UIView *)contentView {
	return self.contentController.view;
}

- (void)layoutContentView:(UIView *)contentView {
	contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;			
	// Adjust the frame of the content view according to the insets.
	contentView.frame = UIEdgeInsetsInsetRect(self.view.bounds, _contentInset);
}

- (void)setContentInset:(UIEdgeInsets)insets {
	if (UIEdgeInsetsEqualToEdgeInsets(insets, _contentInset)) return;

	_contentInset = insets;
	[self.view setNeedsLayout];
}

- (void)setBackgroundView:(UIView *)backgroundView {
	if (_backgroundView == backgroundView) return;
	
	[_backgroundView removeFromSuperview];
	_backgroundView = backgroundView;
	if (_backgroundView) {
		_backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		if (self.isViewLoaded) {
			_backgroundView.frame = self.view.bounds;
			[self.view insertSubview:_backgroundView atIndex:0];
		}
	}
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	if (!_isTransitioningContentView) {
		[self layoutContentView:self.contentView];
	}
}




#pragma mark - Update navigation bar and toolbar

- (void)updateNavigationBarFrom:(UIViewController *)contentController {
	[self unregisterKVOForNavigationBar];
	
	if (_inheritsTitle) {
		self.title = contentController.title;
		self.navigationItem.title = contentController.navigationItem.title;
		[contentController addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
		[contentController addObserver:self forKeyPath:@"navigationItem.title" options:NSKeyValueObservingOptionNew context:nil];
	}		
	if (_inheritsTitleView) {
		self.navigationItem.titleView = contentController.navigationItem.titleView;
		[contentController addObserver:self forKeyPath:@"navigationItem.titleView" options:NSKeyValueObservingOptionNew context:nil];
	}
	if (_inheritsLeftBarButtonItem) {
		[self.navigationItem setLeftBarButtonItem:contentController.navigationItem.leftBarButtonItem animated:_isViewVisible];
		[contentController addObserver:self forKeyPath:@"navigationItem.leftBarButtonItem" options:NSKeyValueObservingOptionNew context:nil];
	}
	if (_inheritsRightBarButtonItem) {
		[self.navigationItem setRightBarButtonItem:contentController.navigationItem.rightBarButtonItem animated:_isViewVisible];
		[contentController addObserver:self forKeyPath:@"navigationItem.rightBarButtonItem" options:NSKeyValueObservingOptionNew context:nil];
	}
	if (_inheritsBackBarButtonItem) {
		[self.navigationItem setBackBarButtonItem:contentController.navigationItem.backBarButtonItem];
		[contentController addObserver:self forKeyPath:@"navigationItem.backBarButtonItem" options:NSKeyValueObservingOptionNew context:nil];
	}
}

- (void)updateToolbarFrom:(UIViewController *)contentController {
	[self unregisterKVOForToolbar];

	if (_inheritsToolbarItems) {
		if ([contentController.toolbarItems count] > 0) {
			if (_isViewVisible) {
				[self.navigationController setToolbarHidden:NO animated:_isViewVisible];
			}
			[self setToolbarItems:contentController.toolbarItems animated:_isViewVisible];
		} else {
			if (_isViewVisible) {
				[self.navigationController setToolbarHidden:YES animated:_isViewVisible];
			}
			[self setToolbarItems:nil];
		}

		[contentController addObserver:self forKeyPath:@"toolbarItems" options:NSKeyValueObservingOptionNew context:nil];
	}	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == _contentController) {
		id value = [change objectForKey:NSKeyValueChangeNewKey];
		if (value == [NSNull null]) {
			value = nil;
		}
		
		if ([keyPath isEqualToString:@"navigationItem.leftBarButtonItem"]) {
			[self.navigationItem setLeftBarButtonItem:value animated:_isViewVisible];
		} else if ([keyPath isEqualToString:@"navigationItem.rightBarButtonItem"]) {
			[self.navigationItem setRightBarButtonItem:value animated:_isViewVisible];
		} else if ([keyPath isEqualToString:@"navigationItem.backBarButtonItem"]) {
			[self.navigationItem setBackBarButtonItem:value];
		} else {
			if ([keyPath isEqualToString:@"toolbarItems"]) {
				if (_isViewVisible) {
					[self.navigationController setToolbarHidden:([(NSArray *)value count] == 0) animated:_isViewVisible];
				}
			}
			[self setValue:value forKeyPath:keyPath];
		}		
	}	
}




#pragma mark - View events

- (void)viewDidLoad {
	[super viewDidLoad];

	// Update bar items.
	[self updateNavigationBarFrom:_contentController];
	[self updateToolbarFrom:_contentController];

	// Add background view.
	if (_backgroundView) {
		_backgroundView.frame = self.view.bounds;
		[self.view insertSubview:_backgroundView atIndex:0];
	}

	// Add content view.
	if (self.contentView) {
		[self.view addSubview:self.contentView];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	_isViewVisible = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	_isViewVisible = NO;
}



#pragma mark - Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return [_contentController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (BOOL)shouldAutorotate {
	return [_contentController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
	return [_contentController supportedInterfaceOrientations];
}



@end
