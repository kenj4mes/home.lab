"""
Browser Module - Sovereign Agent Web Interaction
Playwright-based Web Browsing

The agent's ability to interact with the web:
- Navigate to URLs
- Extract content
- Fill forms
- Click elements
"""

import asyncio
from typing import Any, Optional

import structlog

logger = structlog.get_logger(__name__)


class BrowserModule:
    """
    Browser Module - Web Interaction
    
    Uses Playwright for headless browser automation.
    
    Capabilities:
    - Navigate to URLs
    - Extract page content
    - Take screenshots
    - Fill forms
    - Click elements
    - Execute JavaScript
    
    Example:
        >>> browser = BrowserModule()
        >>> await browser.initialize()
        >>> content = await browser.get_content("https://example.com")
    """
    
    def __init__(
        self,
        headless: bool = True,
        timeout: int = 30000,
    ):
        """
        Initialize Browser Module.
        
        Args:
            headless: Run in headless mode
            timeout: Default timeout in milliseconds
        """
        self.headless = headless
        self.timeout = timeout
        
        self._playwright = None
        self._browser = None
        self._context = None
        
        # Statistics
        self.pages_visited: int = 0
        self.screenshots_taken: int = 0
        
    async def initialize(self) -> None:
        """Initialize Playwright browser"""
        try:
            from playwright.async_api import async_playwright
            
            self._playwright = await async_playwright().start()
            self._browser = await self._playwright.chromium.launch(
                headless=self.headless
            )
            self._context = await self._browser.new_context(
                viewport={"width": 1280, "height": 720}
            )
            
            logger.info("browser.initialized", headless=self.headless)
            
        except ImportError:
            logger.warning("browser.playwright_not_installed",
                         note="Run: pip install playwright && playwright install")
        except Exception as e:
            logger.error("browser.init_failed", error=str(e))
    
    # ==========================================================================
    # NAVIGATION
    # ==========================================================================
    
    async def goto(
        self,
        url: str,
        wait_until: str = "domcontentloaded",
    ) -> dict[str, Any]:
        """
        Navigate to a URL.
        
        Args:
            url: URL to navigate to
            wait_until: When to consider navigation complete
            
        Returns:
            Navigation result
        """
        if not self._context:
            return {"status": "error", "error": "Browser not initialized"}
        
        try:
            page = await self._context.new_page()
            
            response = await page.goto(
                url,
                wait_until=wait_until,
                timeout=self.timeout
            )
            
            self.pages_visited += 1
            
            return {
                "status": "success",
                "url": url,
                "final_url": page.url,
                "title": await page.title(),
                "status_code": response.status if response else None,
                "_page": page,  # Keep page reference
            }
            
        except Exception as e:
            logger.error("browser.goto_failed", url=url, error=str(e))
            return {"status": "error", "error": str(e)}
    
    async def get_content(
        self,
        url: str,
        selector: Optional[str] = None,
    ) -> dict[str, Any]:
        """
        Get text content from a URL.
        
        Args:
            url: URL to fetch
            selector: Optional CSS selector for specific element
            
        Returns:
            Page content
        """
        result = await self.goto(url)
        
        if result.get("status") != "success":
            return result
        
        page = result.get("_page")
        
        try:
            if selector:
                element = await page.query_selector(selector)
                if element:
                    content = await element.text_content()
                else:
                    content = None
            else:
                content = await page.text_content("body")
            
            await page.close()
            
            return {
                "status": "success",
                "url": url,
                "title": result.get("title"),
                "content": content,
            }
            
        except Exception as e:
            await page.close()
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # SCREENSHOTS
    # ==========================================================================
    
    async def screenshot(
        self,
        url: str,
        full_page: bool = False,
    ) -> dict[str, Any]:
        """
        Take a screenshot of a URL.
        
        Args:
            url: URL to screenshot
            full_page: Capture entire page (not just viewport)
            
        Returns:
            Screenshot bytes
        """
        result = await self.goto(url)
        
        if result.get("status") != "success":
            return result
        
        page = result.get("_page")
        
        try:
            screenshot = await page.screenshot(full_page=full_page)
            
            await page.close()
            
            self.screenshots_taken += 1
            
            return {
                "status": "success",
                "url": url,
                "title": result.get("title"),
                "screenshot": screenshot,
            }
            
        except Exception as e:
            await page.close()
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # INTERACTION
    # ==========================================================================
    
    async def click(
        self,
        page: Any,
        selector: str,
    ) -> dict[str, Any]:
        """
        Click an element.
        
        Args:
            page: Playwright page object
            selector: CSS selector for element
            
        Returns:
            Click result
        """
        try:
            await page.click(selector, timeout=self.timeout)
            return {"status": "success", "selector": selector}
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    async def fill(
        self,
        page: Any,
        selector: str,
        value: str,
    ) -> dict[str, Any]:
        """
        Fill an input field.
        
        Args:
            page: Playwright page object
            selector: CSS selector for input
            value: Value to fill
            
        Returns:
            Fill result
        """
        try:
            await page.fill(selector, value, timeout=self.timeout)
            return {"status": "success", "selector": selector}
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    async def evaluate(
        self,
        page: Any,
        script: str,
    ) -> dict[str, Any]:
        """
        Execute JavaScript on page.
        
        Args:
            page: Playwright page object
            script: JavaScript code
            
        Returns:
            Script result
        """
        try:
            result = await page.evaluate(script)
            return {"status": "success", "result": result}
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # EXTRACTION
    # ==========================================================================
    
    async def get_links(self, url: str) -> dict[str, Any]:
        """
        Extract all links from a page.
        
        Args:
            url: URL to extract from
            
        Returns:
            List of links
        """
        result = await self.goto(url)
        
        if result.get("status") != "success":
            return result
        
        page = result.get("_page")
        
        try:
            links = await page.evaluate("""
                () => Array.from(document.querySelectorAll('a[href]'))
                    .map(a => ({href: a.href, text: a.textContent.trim()}))
                    .filter(l => l.href.startsWith('http'))
            """)
            
            await page.close()
            
            return {
                "status": "success",
                "url": url,
                "links": links,
            }
            
        except Exception as e:
            await page.close()
            return {"status": "error", "error": str(e)}
    
    async def get_html(self, url: str) -> dict[str, Any]:
        """
        Get raw HTML from a URL.
        
        Args:
            url: URL to fetch
            
        Returns:
            Raw HTML
        """
        result = await self.goto(url)
        
        if result.get("status") != "success":
            return result
        
        page = result.get("_page")
        
        try:
            html = await page.content()
            await page.close()
            
            return {
                "status": "success",
                "url": url,
                "html": html,
            }
            
        except Exception as e:
            await page.close()
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> dict[str, Any]:
        """Get browser status"""
        return {
            "initialized": self._browser is not None,
            "headless": self.headless,
            "pages_visited": self.pages_visited,
            "screenshots_taken": self.screenshots_taken,
        }
    
    async def close(self) -> None:
        """Cleanup browser resources"""
        if self._context:
            await self._context.close()
        if self._browser:
            await self._browser.close()
        if self._playwright:
            await self._playwright.stop()
        
        self._context = None
        self._browser = None
        self._playwright = None
        
        logger.info("browser.closed")
