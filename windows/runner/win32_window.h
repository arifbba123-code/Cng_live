#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  bool CreateAndShow(const std::wstring& title, const Point& origin,
                      const Size& size);

  void SetChildContent(HWND content);

  RECT GetClientArea();

  HWND GetHandle();

  void SetQuitOnClose(bool quit_on_close);

  virtual bool OnCreate();
  virtual void OnDestroy();

 protected:
  virtual LRESULT MessageHandler(HWND window, UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  void Destroy();

  static Win32Window* GetThisFromHandle(HWND const window) noexcept;
  static int Scale(int source, double scale_factor);
  static void EnableFullDpiSupportIfAvailable(HWND hwnd);
  void Show();

 private:
  friend class WindowClassRegistrar;

  static LRESULT CALLBACK WndProc(HWND const window, UINT const message,
                                   WPARAM const wparam,
                                   LPARAM const lparam) noexcept;

  bool OnCreate2();

  bool quit_on_close_ = false;

  HWND window_handle_ = nullptr;

  HWND child_content_ = nullptr;
};

#endif  // RUNNER_WIN32_WINDOW_H_
