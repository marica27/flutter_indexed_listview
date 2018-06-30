import 'package:flutter/rendering.dart';

import 'package:flutter/widgets.dart';

class IndexedListView extends ListView {
  IndexedListView({
    this.initalIndex,
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsetsGeometry padding,
    double itemExtent,
    @required IndexedWidgetBuilder itemBuilder,
    int itemCount,
    bool addAutomaticKeepAlives: true,
    bool addRepaintBoundaries: true,
    double cacheExtent,
  }) : super.builder(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
    itemExtent: itemExtent,
    itemBuilder: itemBuilder,
    itemCount: itemCount,
    addAutomaticKeepAlives: addAutomaticKeepAlives,
    addRepaintBoundaries: true,
    cacheExtent: cacheExtent,
  );

  int initalIndex;

  @override
  Widget buildChildLayout(BuildContext context) {
    if (itemExtent != null) {
      return new SliverFixedExtentList(
        delegate: childrenDelegate,
        itemExtent: itemExtent,
      );
    }

    print("IndexedListView ${initalIndex}");
    return new IndexedSliverList(
        delegate: childrenDelegate,
        initialIndex: initalIndex,
        correctOffset: (double value) {
          controller.position.correctPixels(value);
        });
  }
}

typedef VoidCallBackWithDouble(double value);

class IndexedSliverList extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places box children in a linear array.
  const IndexedSliverList({
    Key key,
    this.initialIndex: 0,
    @required SliverChildBuilderDelegate delegate,
    @required this.correctOffset,
  }) : super(key: key, delegate: delegate);

  final int initialIndex;
  final VoidCallBackWithDouble correctOffset;

  @override
  RenderIndexedSliverList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;

    return new RenderIndexedSliverList(
        childManager: element,
        initialIndex: initialIndex,
        correctOffset: correctOffset);
  }

  @override
  void updateRenderObject(BuildContext context, RenderIndexedSliverList renderObject) {
    renderObject.initialIndex = initialIndex;
    renderObject.isBuildFirstTime = true;
    super.updateRenderObject(context, renderObject);
  }

}

class RenderIndexedSliverList extends RenderSliverList {
  int initialIndex;
  final VoidCallBackWithDouble correctOffset;
  bool isBuildFirstTime = true;

  RenderIndexedSliverList({
    @required RenderSliverBoxChildManager childManager,
    this.initialIndex,
    @required this.correctOffset,
  }) : super(childManager: childManager);


  @override
  void performLayout() {
    print(
        "RenderIndexedSliverList performLayout initialIndex=${initialIndex} isBuildFirstTime=$isBuildFirstTime");
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    // Make sure we have at least one child to start from.
    if (firstChild == null) {
      if (!addInitialChild()) {
        // There are no children.
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }
    // We have at least one child.

    final BoxConstraints childConstraints = constraints.asBoxConstraints();

    // Make sure we've laid out at least one child.
    firstChild.layout(childConstraints, parentUsesSize: true);


    RenderBox child = firstChild;
    int leadingGarbage = 0;
    int trailingGarbage = 0;
    bool reachedEnd = false;
    double endScrollOffset = childScrollOffset(child) + paintExtentOf(child);

    // These variables track the range of children that we have laid out. Within
    // this range, the children have consecutive indices. Outside this range,
    // it's possible for a child to get removed without notice.
    RenderBox leadingChildWithLayout, trailingChildWithLayout;

    leadingChildWithLayout = firstChild;
    trailingChildWithLayout = firstChild;

    bool inLayoutRange = true;
    int index = indexOf(child);

    bool advance() {
      print("advance ${indexOf(child)}");
      // returns true if we advanced, false if we have no more children
      // This function is used in --two-- three different places below, to avoid code duplication.
      assert(child != null);
      if (child == trailingChildWithLayout)
        inLayoutRange = false;
      child = childAfter(child);
      if (child == null)
        inLayoutRange = false;
      index += 1;
      if (!inLayoutRange) {
        if (child == null || indexOf(child) != index) {
          // We are missing a child. Insert it (and lay it out) if possible.
          child = insertAndLayoutChild(childConstraints,
            after: trailingChildWithLayout,
            parentUsesSize: true,
          );
          if (child == null) {
            // We have run out of children.
            return false;
          }
        } else {
          // Lay out the child.
          child.layout(childConstraints, parentUsesSize: true);
        }
        trailingChildWithLayout = child;
      }
      assert(child != null);
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      childParentData.layoutOffset = endScrollOffset;
      assert(childParentData.index == index);
      endScrollOffset = childScrollOffset(child) + paintExtentOf(child);
      return true;
    }

    SliverConstraints newSliverConstraints = constraints;

    //If initialIndex is defined:
    // If it runs first time scrollOffset is 0.0. I don't know how to define cases
    // when user just scrolls after jumpToIndex and user wants again jumpToIndex.

    // lets find the scrollOffset for item with initialIndex
    print("initialIndex=$initialIndex offset=${constraints.scrollOffset} isBuildFirstTime=$isBuildFirstTime");
    if (initialIndex != null && constraints.scrollOffset == 0.0 &&
        isBuildFirstTime) {
      print("// do layout for all children before initialIndex");
      // do layout for all children before initialIndex
      while (indexOf(child) < initialIndex - 1) {
        leadingGarbage += 1;
        print("leadingGarbage=${leadingGarbage}");
        advance();
      }
      print("find endScrollOffset = ${endScrollOffset}");
      //this will set right offset for ScrollController
      correctOffset(endScrollOffset);
      isBuildFirstTime = false;
      newSliverConstraints =
          constraints.copyWith(scrollOffset: endScrollOffset);
    }
    print("firstChild=${indexOf(firstChild)} child=${indexOf(child)}");


    final double scrollOffset = newSliverConstraints.scrollOffset +
        constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = newSliverConstraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;


    // This algorithm in principle is straight-forward: find the first child
    // that overlaps the given scrollOffset, creating more children at the top
    // of the list if necessary, then walk down the list updating and laying out
    // each child and adding more at the end if necessary until we have enough
    // children to cover the entire viewport.
    //
    // It is complicated by one minor issue, which is that any time you update
    // or create a child, it's possible that the some of the children that
    // haven't yet been laid out will be removed, leaving the list in an
    // inconsistent state, and requiring that missing nodes be recreated.
    //
    // To keep this mess tractable, this algorithm starts from what is currently
    // the first child, if any, and then walks up and/or down from there, so
    // that the nodes that might get removed are always at the edges of what has
    // already been laid out.


    // Find the last child that is at or before the scrollOffset.
    RenderBox earliestUsefulChild = firstChild;
    for (double earliestScrollOffset = childScrollOffset(earliestUsefulChild);
    earliestScrollOffset > scrollOffset;
    earliestScrollOffset = childScrollOffset(earliestUsefulChild)) {
      // We have to add children before the earliestUsefulChild.
      earliestUsefulChild =
          insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);

      if (earliestUsefulChild == null) {
        final SliverMultiBoxAdaptorParentData childParentData = firstChild
            .parentData;
        childParentData.layoutOffset = 0.0;

        if (scrollOffset == 0.0) {
          earliestUsefulChild = firstChild;
          leadingChildWithLayout = earliestUsefulChild;
          trailingChildWithLayout ??= earliestUsefulChild;
          break;
        } else {
          // We ran out of children before reaching the scroll offset.
          // We must inform our parent that this sliver cannot fulfill
          // its contract and that we need a scroll offset correction.
          geometry = new SliverGeometry(
            scrollOffsetCorrection: -scrollOffset,
          );
          return;
        }
      }

      final double firstChildScrollOffset = earliestScrollOffset -
          paintExtentOf(firstChild);
      if (firstChildScrollOffset < 0.0) {
        // The first child doesn't fit within the viewport (underflow) and
        // there may be additional children above it. Find the real first child
        // and then correct the scroll position so that there's room for all and
        // so that the trailing edge of the original firstChild appears where it
        // was before the scroll offset correction.
        // TODO(hansmuller): do this work incrementally, instead of all at once,
        // i.e. find a way to avoid visiting ALL of the children whose offset
        // is < 0 before returning for the scroll correction.
        double correction = 0.0;
        while (earliestUsefulChild != null) {
          assert(firstChild == earliestUsefulChild);
          correction += paintExtentOf(firstChild);
          earliestUsefulChild = insertAndLayoutLeadingChild(
              childConstraints, parentUsesSize: true);
        }
        geometry = new SliverGeometry(
          scrollOffsetCorrection: correction - earliestScrollOffset,
        );
        final SliverMultiBoxAdaptorParentData childParentData = firstChild
            .parentData;
        childParentData.layoutOffset = 0.0;
        return;
      }

      final SliverMultiBoxAdaptorParentData childParentData = earliestUsefulChild
          .parentData;
      childParentData.layoutOffset = firstChildScrollOffset;
      assert(earliestUsefulChild == firstChild);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout ??= earliestUsefulChild;
    }

    // At this point, earliestUsefulChild is the first child, and is a child
    // whose scrollOffset is at or before the scrollOffset, and
    // leadingChildWithLayout and trailingChildWithLayout are either null or
    // cover a range of render boxes that we have laid out with the first being
    // the same as earliestUsefulChild and the last being either at or after the
    // scroll offset.

    assert(earliestUsefulChild == firstChild);
    assert(childScrollOffset(earliestUsefulChild) <= scrollOffset);

    // Make sure we've laid out at least one child.
    if (leadingChildWithLayout == null) {
      earliestUsefulChild.layout(childConstraints, parentUsesSize: true);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout = earliestUsefulChild;
    }

    // Here, earliestUsefulChild is still the first child, it's got a
    // scrollOffset that is at or before our actual scrollOffset, and it has
    // been laid out, and is in fact our leadingChildWithLayout. It's possible
    // that some children beyond that one have also been laid out.

    //this reinit variables before advance()
    inLayoutRange = true;
    print("child = ${indexOf(child)}");
//    child = earliestUsefulChild;
//    index = indexOf(child);
    endScrollOffset = childScrollOffset(child) + paintExtentOf(child);


    // Find the first child that ends after the scroll offset.
    print("// Find the first child that ends after the scroll offset.");
    while (endScrollOffset < scrollOffset) {
      leadingGarbage += 1;
      print("$endScrollOffset  < $scrollOffset leadingGarbage=$leadingGarbage  index=$index ${indexOf(child)}");
      if (!advance()) {
        assert(leadingGarbage == childCount);
        assert(child == null);
        // we want to make sure we keep the last child around so we know the end scroll offset
        collectGarbage(leadingGarbage - 1, 0);
        assert(firstChild == lastChild);
        final double extent = childScrollOffset(lastChild) +
            paintExtentOf(lastChild);
        geometry = new SliverGeometry(
          scrollExtent: extent,
          paintExtent: 0.0,
          maxPaintExtent: extent,
        );
        return;
      }
    }
    print("$endScrollOffset  < $scrollOffset leadingGarbage=$leadingGarbage  index=$index");
    print("// Now find the first child that ends after our end $targetEndScrollOffset");
    // Now find the first child that ends after our end.
    while (endScrollOffset < targetEndScrollOffset) {
      if (!advance()) {
        reachedEnd = true;
        break;
      }
    }

    // Finally count up all the remaining children and label them as garbage.
    if (child != null) {
      child = childAfter(child);
      while (child != null) {
        trailingGarbage += 1;
        child = childAfter(child);
      }
    }

    // At this point everything should be good to go, we just have to clean up
    // the garbage and report the geometry.
    print("$this depth=${this.depth} firstChild=${this.firstChild} ${leadingGarbage} ${trailingGarbage}");
    collectGarbage(leadingGarbage, trailingGarbage);

    print("$this depth=${this.depth} firstChild=${this.firstChild} ");
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    double estimatedMaxScrollOffset;
    if (reachedEnd) {
      estimatedMaxScrollOffset = endScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        newSliverConstraints,
        firstIndex: indexOf(firstChild),
        lastIndex: indexOf(lastChild),
        leadingScrollOffset: childScrollOffset(firstChild),
        trailingScrollOffset: endScrollOffset,
      );
      assert(estimatedMaxScrollOffset >=
          endScrollOffset - childScrollOffset(firstChild));
    }
    final double paintExtent = calculatePaintOffset(
      newSliverConstraints,
      from: childScrollOffset(firstChild),
      to: endScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      newSliverConstraints,
      from: childScrollOffset(firstChild),
      to: endScrollOffset,
    );
    geometry = new SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: endScrollOffset > targetEndScrollOffset ||
          newSliverConstraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    if (estimatedMaxScrollOffset == endScrollOffset)
      childManager.setDidUnderflow(true);
    childManager.didFinishLayout();
  }
}