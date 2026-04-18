import * as React from "react";

export type PageView = "home" | "library-settings" | "memories" | "memory-detail";

export interface PageViewContextValue {
  page: PageView;
  setPage: (page: PageView) => void;
}

export const PageViewContext = React.createContext<PageViewContextValue>({
  page: "home",
  setPage: () => {},
});
