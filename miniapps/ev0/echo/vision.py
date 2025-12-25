"""
Digital Eye - Sovereign Agent Vision
Visual Perception via GPT-4V + Playwright

The agent's visual sense:
- Screenshot analysis
- Image understanding
- Web visual interaction
"""

import base64
import os
from typing import Any, Optional

import httpx
import structlog

logger = structlog.get_logger(__name__)


class DigitalEye:
    """
    Digital Eye - Visual Perception
    
    Uses GPT-4V (Vision) for image understanding and
    Playwright/Selenium for web screenshots.
    
    Capabilities:
    - Analyze images/screenshots
    - Extract text from images (OCR)
    - Understand UI elements
    - Describe visual content
    
    Example:
        >>> eye = DigitalEye(openai_api_key="...")
        >>> await eye.initialize()
        >>> analysis = await eye.see("https://example.com/image.png")
        >>> print(analysis["description"])
    """
    
    def __init__(
        self,
        openai_api_key: Optional[str] = None,
        model: str = "gpt-4o",
    ):
        """
        Initialize Digital Eye.
        
        Args:
            openai_api_key: OpenAI API key for GPT-4V
            model: Vision model to use
        """
        self.api_key = openai_api_key or os.getenv("OPENAI_API_KEY")
        self.model = model
        
        self._client: httpx.AsyncClient | None = None
        self._browser = None
        
        # Statistics
        self.images_analyzed: int = 0
        self.screenshots_taken: int = 0
        
    async def initialize(self) -> None:
        """Initialize HTTP client"""
        self._client = httpx.AsyncClient(
            base_url="https://api.openai.com/v1",
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            },
            timeout=60.0
        )
        
        logger.info("eye.initialized", model=self.model)
    
    # ==========================================================================
    # IMAGE ANALYSIS
    # ==========================================================================
    
    async def see(
        self,
        image: str | bytes,
        prompt: str = "Describe this image in detail.",
        max_tokens: int = 500,
    ) -> dict[str, Any]:
        """
        Analyze an image using GPT-4V.
        
        Args:
            image: URL, file path, or raw bytes
            prompt: What to analyze/describe
            max_tokens: Max response length
            
        Returns:
            Analysis result
        """
        if not self._client:
            return {"status": "error", "error": "Not initialized"}
        
        try:
            # Prepare image content
            image_content = await self._prepare_image(image)
            
            # Build API request
            response = await self._client.post(
                "/chat/completions",
                json={
                    "model": self.model,
                    "messages": [
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": prompt},
                                image_content
                            ]
                        }
                    ],
                    "max_tokens": max_tokens,
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                self.images_analyzed += 1
                
                description = data["choices"][0]["message"]["content"]
                
                return {
                    "status": "success",
                    "description": description,
                    "model": self.model,
                    "tokens_used": data.get("usage", {}).get("total_tokens", 0),
                }
            else:
                return {
                    "status": "error",
                    "error": response.text,
                    "code": response.status_code
                }
                
        except Exception as e:
            logger.error("eye.see_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    async def _prepare_image(self, image: str | bytes) -> dict:
        """Prepare image for API request"""
        # URL
        if isinstance(image, str) and image.startswith(("http://", "https://")):
            return {
                "type": "image_url",
                "image_url": {"url": image}
            }
        
        # File path
        if isinstance(image, str) and os.path.exists(image):
            with open(image, "rb") as f:
                image = f.read()
        
        # Raw bytes - convert to base64
        if isinstance(image, bytes):
            b64 = base64.b64encode(image).decode("utf-8")
            # Detect mime type (simplified)
            if image[:8] == b'\x89PNG\r\n\x1a\n':
                mime = "image/png"
            elif image[:2] == b'\xff\xd8':
                mime = "image/jpeg"
            elif image[:6] in (b'GIF87a', b'GIF89a'):
                mime = "image/gif"
            else:
                mime = "image/png"
            
            return {
                "type": "image_url",
                "image_url": {
                    "url": f"data:{mime};base64,{b64}"
                }
            }
        
        raise ValueError(f"Invalid image input: {type(image)}")
    
    # ==========================================================================
    # SPECIALIZED ANALYSIS
    # ==========================================================================
    
    async def read_text(self, image: str | bytes) -> dict[str, Any]:
        """
        Extract text from an image (OCR).
        
        Args:
            image: Image to read
            
        Returns:
            Extracted text
        """
        return await self.see(
            image,
            prompt="Extract all text visible in this image. Preserve the layout and formatting as much as possible. If no text is visible, say 'No text found'."
        )
    
    async def analyze_ui(self, image: str | bytes) -> dict[str, Any]:
        """
        Analyze UI elements in a screenshot.
        
        Args:
            image: Screenshot image
            
        Returns:
            UI analysis
        """
        return await self.see(
            image,
            prompt="""Analyze this UI screenshot and identify:
1. Main sections/components
2. Interactive elements (buttons, links, inputs)
3. Current state/context
4. Any important information displayed

Format as structured analysis.""",
            max_tokens=800
        )
    
    async def compare_images(
        self,
        image1: str | bytes,
        image2: str | bytes,
    ) -> dict[str, Any]:
        """
        Compare two images and describe differences.
        
        Args:
            image1: First image
            image2: Second image
            
        Returns:
            Comparison result
        """
        if not self._client:
            return {"status": "error", "error": "Not initialized"}
        
        try:
            content1 = await self._prepare_image(image1)
            content2 = await self._prepare_image(image2)
            
            response = await self._client.post(
                "/chat/completions",
                json={
                    "model": self.model,
                    "messages": [
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": "Compare these two images. What are the differences? What stayed the same?"},
                                content1,
                                content2
                            ]
                        }
                    ],
                    "max_tokens": 600,
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                self.images_analyzed += 2
                
                return {
                    "status": "success",
                    "comparison": data["choices"][0]["message"]["content"],
                }
            else:
                return {"status": "error", "error": response.text}
                
        except Exception as e:
            logger.error("eye.compare_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # SCREENSHOT
    # ==========================================================================
    
    async def screenshot(self, url: str) -> dict[str, Any]:
        """
        Take a screenshot of a webpage.
        
        Args:
            url: URL to screenshot
            
        Returns:
            Screenshot bytes and metadata
        """
        try:
            from playwright.async_api import async_playwright
            
            async with async_playwright() as p:
                browser = await p.chromium.launch()
                page = await browser.new_page()
                await page.goto(url, timeout=30000)
                
                screenshot = await page.screenshot()
                title = await page.title()
                
                await browser.close()
            
            self.screenshots_taken += 1
            
            return {
                "status": "success",
                "screenshot": screenshot,
                "url": url,
                "title": title,
            }
            
        except ImportError:
            return {
                "status": "error",
                "error": "Playwright not installed. Run: pip install playwright && playwright install"
            }
        except Exception as e:
            logger.error("eye.screenshot_failed", url=url, error=str(e))
            return {"status": "error", "error": str(e)}
    
    async def screenshot_and_analyze(
        self,
        url: str,
        prompt: str = "Describe what you see on this webpage.",
    ) -> dict[str, Any]:
        """
        Screenshot a URL and analyze it.
        
        Args:
            url: URL to capture
            prompt: Analysis prompt
            
        Returns:
            Screenshot and analysis
        """
        # Take screenshot
        screenshot_result = await self.screenshot(url)
        
        if screenshot_result.get("status") != "success":
            return screenshot_result
        
        # Analyze
        analysis = await self.see(
            screenshot_result["screenshot"],
            prompt=prompt
        )
        
        return {
            "status": analysis.get("status"),
            "url": url,
            "title": screenshot_result.get("title"),
            "analysis": analysis.get("description"),
        }
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> dict[str, Any]:
        """Get eye status"""
        return {
            "model": self.model,
            "images_analyzed": self.images_analyzed,
            "screenshots_taken": self.screenshots_taken,
        }
    
    async def close(self) -> None:
        """Cleanup resources"""
        if self._client:
            await self._client.aclose()
            self._client = None
        logger.info("eye.closed")
